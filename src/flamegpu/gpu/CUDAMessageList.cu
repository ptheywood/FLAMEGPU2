#include <cuda_runtime.h>
#include <device_launch_parameters.h>

#include "flamegpu/gpu/CUDAMessageList.h"

#include "flamegpu/gpu/CUDAMessage.h"
#include "flamegpu/gpu/detail/CUDAErrorChecking.cuh"
#include "flamegpu/runtime/messaging/MessageBruteForce/MessageBruteForceHost.h"
#include "flamegpu/gpu/CUDAScatter.cuh"

namespace flamegpu {

/**
* CUDAMessageList class
* @brief populates CUDA message map
*/
CUDAMessageList::CUDAMessageList(CUDAMessage& cuda_message, CUDAScatter &scatter, const unsigned int &streamId)
    : message(cuda_message) {
    // allocate message lists
    allocateDeviceMessageList(d_list);
    allocateDeviceMessageList(d_swap_list);
    if (message.getMessageCount() != 0) {
        {
            auto &a = cuda_message.getReadList();
            auto &_a = d_list;
            scatter.scatterAll(streamId, 0, message.getMessageDescription().variables, a, _a, message.getMessageCount(), 0);
        }
        {  // Is copying writelist redundant?
            auto &a = cuda_message.getWriteList();
            auto &_a = d_swap_list;
            scatter.scatterAll(streamId, 0, message.getMessageDescription().variables, a, _a, message.getMessageCount(), 0);
        }
    }
}

/**
 * A destructor.
 * @brief Destroys the CUDAMessageList object
 */
CUDAMessageList::~CUDAMessageList() {
    cleanupAllocatedData();
}

void CUDAMessageList::cleanupAllocatedData() {
    // clean up
    releaseDeviceMessageList(d_list);
    releaseDeviceMessageList(d_swap_list);
}

void CUDAMessageList::allocateDeviceMessageList(CUDAMessageMap &memory_map) {
    // we use the  messages memory map to iterate the  message variables and do allocation within our GPU hash map
    const auto &mem = message.getMessageDescription().variables;

    // for each variable allocate a device array and add to map
    for (const auto &mm : mem) {
        // get the variable name
        std::string var_name = mm.first;

        // get the variable size from  message description
        size_t var_size = mm.second.type_size * mm.second.elements;

        // do the device allocation
        void * d_ptr;

#ifdef UNIFIED_GPU_MEMORY
        // unified memory allocation
        gpuErrchk(cudaMallocManaged(reinterpret_cast<void**>(&d_ptr), var_size *  message.getMaximumListSize()))
#else
        // non unified memory allocation
        gpuErrchk(cudaMalloc(reinterpret_cast<void**>(&d_ptr), var_size * message.getMaximumListSize()));
#endif

        // store the pointer in the map
        memory_map.insert(CUDAMessageMap::value_type(var_name, d_ptr));
    }
}

void CUDAMessageList::releaseDeviceMessageList(CUDAMessageMap& memory_map) {
    // for each device pointer in the cuda memory map we need to free these
    for (const auto &mm : memory_map) {
        // free the memory on the device
        gpuErrchk(cudaFree(mm.second));
    }
}

void CUDAMessageList::zeroDeviceMessageList(CUDAMessageMap& memory_map) {
    // for each device pointer in the cuda memory map set the values to 0
    for (const auto &mm : memory_map) {
        // get the variable size from message description
        const auto var = message.getMessageDescription().variables.at(mm.first);
        const size_t var_size = var.type_size * var.elements;

        // set the memory to zero
        gpuErrchk(cudaMemset(mm.second, 0, var_size*message.getMaximumListSize()));
    }
}

void* CUDAMessageList::getReadMessageListVariablePointer(std::string variable_name) {
    CUDAMessageMap::iterator mm = d_list.find(variable_name);
    if (mm == d_list.end()) {
        THROW exception::InvalidMessageVar("Variable '%s' was not found in message '%s', "
          "in CUDAMessageList::getReadMessageListVariablePointer()",
          variable_name.c_str(), message.getMessageDescription().name.c_str());
    }

    return mm->second;
}
void* CUDAMessageList::getWriteMessageListVariablePointer(std::string variable_name) {
    CUDAMessageMap::iterator mm = d_swap_list.find(variable_name);
    if (mm == d_swap_list.end()) {
        THROW exception::InvalidMessageVar("Variable '%s' was not found in message '%s', "
            "in CUDAMessageList::getWriteMessageListVariablePointer()",
            variable_name.c_str(), message.getMessageDescription().name.c_str());
    }

    return mm->second;
}

void CUDAMessageList::zeroMessageData() {
    zeroDeviceMessageList(d_list);
    zeroDeviceMessageList(d_swap_list);
}


void CUDAMessageList::swap() {
    std::swap(d_list, d_swap_list);
}

unsigned int CUDAMessageList::scatter(const unsigned int &newCount, CUDAScatter &scatter, const unsigned int &streamId, const bool &append) {
    if (append) {
        unsigned int oldCount = message.getMessageCount();
        return oldCount + scatter.scatter(streamId,
            0,
            CUDAScatter::Type::MESSAGE_OUTPUT,
            message.getMessageDescription().variables,
            d_swap_list, d_list,
            newCount,
            oldCount);
    } else {
        return scatter.scatter(streamId,
            0,
            CUDAScatter::Type::MESSAGE_OUTPUT,
            message.getMessageDescription().variables,
            d_swap_list, d_list,
            newCount,
            0);
    }
}
unsigned int CUDAMessageList::scatterAll(const unsigned int &newCount, CUDAScatter &scatter, const unsigned int &streamId) {
    unsigned int oldCount = message.getMessageCount();
    return oldCount + scatter.scatterAll(streamId,
        0,
        message.getMessageDescription().variables,
        d_swap_list, d_list,
        newCount,
        oldCount);
}

}  // namespace flamegpu

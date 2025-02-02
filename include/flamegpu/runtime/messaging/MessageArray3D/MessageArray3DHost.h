#ifndef INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGEARRAY3D_MESSAGEARRAY3DHOST_H_
#define INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGEARRAY3D_MESSAGEARRAY3DHOST_H_

#include <string>
#include <memory>
#include <array>

#include "flamegpu/model/Variable.h"
#include "flamegpu/runtime/messaging/MessageArray3D.h"
#include "flamegpu/runtime/messaging/MessageBruteForce/MessageBruteForceHost.h"


namespace flamegpu {

/**
 * Blank handler, brute force requires no index or special allocations
 * Only stores the length on device
 */
class MessageArray3D::CUDAModelHandler : public MessageSpecialisationHandler {
 public:
    /**
     * Constructor
     * Allocates memory on device for message list length
     * @param a Parent CUDAMessage, used to access message settings, data ptrs etc
     */
     explicit CUDAModelHandler(CUDAMessage &a);
    /** 
     * Destructor.
     * Should free any local host memory (device memory cannot be freed in destructors)
     */
    ~CUDAModelHandler() { }
    /**
     * Allocates memory for the constructed index.
     * Allocates message buffers, and memsets data to 0
     * @param scatter Scatter instance and scan arrays to be used (CUDASimulation::singletons->scatter)
     * @param streamId The stream index to use for accessing stream specific resources such as scan compaction arrays and buffers
     */
    void init(CUDAScatter &scatter, const unsigned int &streamId) override;
    /**
     * Sort messages according to index
     * Detect and report any duplicate indicies/gaps
     * @param scatter Scatter instance and scan arrays to be used (CUDASimulation::singletons->scatter)
     * @param streamId The stream index to use for accessing stream specific resources such as scan compaction arrays and buffers
     * @param stream CUDA stream to be used for async CUDA operations
     */
    void buildIndex(CUDAScatter &scatter, const unsigned int &streamId, const cudaStream_t &stream) override;
    /**
     * Allocates memory for the constructed index.
     * The memory allocation is checked by build index.
     */
    void allocateMetaDataDevicePtr() override;
    /**
     * Releases memory for the constructed index.
     */
    void freeMetaDataDevicePtr() override;
    /**
     * Returns a pointer to the metadata struct, this is required for reading the message data
     */
    const void *getMetaDataDevicePtr() const override { return d_metadata; }

 private:
    /**
     * Host copy of metadata struct (message list length)
     */
    MetaData hd_metadata;
    /**
     * Pointer to device copy of metadata struct (message list length)
     */
    MetaData *d_metadata;
    /**
     * Owning CUDAMessage, provides access to message storage etc
     */
    CUDAMessage &sim_message;
    /**
     * Buffer used by buildIndex if array length > agent count
     */
    unsigned int *d_write_flag;
    /**
     * Allocated length of d_write_flag (in number of uint, not bytes)
     */
    size_type d_write_flag_len;
};

/**
 * Internal data representation of Array messages within model description hierarchy
 * @see Description
 */
struct MessageArray3D::Data : public MessageBruteForce::Data {
    friend class ModelDescription;
    friend struct ModelData;
    std::array<size_type, 3> dimensions;
    virtual ~Data() = default;

    std::unique_ptr<MessageSpecialisationHandler> getSpecialisationHander(CUDAMessage &owner) const override;

    /**
     * Used internally to validate that the corresponding Message type is attached via the agent function shim.
     * @return The std::type_index of the Message type which must be used.
     */
    std::type_index getType() const override;

 protected:
    Data *clone(const std::shared_ptr<const ModelData> & newParent) override;
    /**
     * Copy constructor
     * This is unsafe, should only be used internally, use clone() instead
     */
    Data(const std::shared_ptr<const ModelData> &, const Data &other);
    /**
     * Normal constructor, only to be called by ModelDescription
     */
    Data(const std::shared_ptr<const ModelData> &, const std::string &message_name);
};

/**
 * User accessible interface to Array messages within mode description hierarchy
 * @see Data
 */
class MessageArray3D::Description : public MessageBruteForce::Description {
    /**
     * Data store class for this description, constructs instances of this class
     */
    friend struct Data;

 protected:
    /**
     * Constructors
     */
    Description(const std::shared_ptr<const ModelData> & _model, Data *const data);
    /**
     * Default copy constructor, not implemented
     */
     Description(const Description &other_message) = delete;
    /**
     * Default move constructor, not implemented
     */
     Description(Description &&other_message) noexcept = delete;
    /**
     * Default copy assignment, not implemented
     */
     Description& operator=(const Description &other_message) = delete;
    /**
     * Default move assignment, not implemented
     */
     Description& operator=(Description &&other_message) noexcept = delete;

 public:
    void setDimensions(const size_type &len_x, const size_type &len_y, const size_type &len_Z);
    void setDimensions(const std::array<size_type, 3> &dims);

    std::array<size_type, 3> getDimensions() const;
    size_type getDimX() const;
    size_type getDimY() const;
    size_type getDimZ() const;
};

}  // namespace flamegpu

#endif  // INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGEARRAY3D_MESSAGEARRAY3DHOST_H_

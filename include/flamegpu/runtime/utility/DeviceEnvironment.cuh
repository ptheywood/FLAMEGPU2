#ifndef INCLUDE_FLAMEGPU_RUNTIME_UTILITY_DEVICEENVIRONMENT_CUH_
#define INCLUDE_FLAMEGPU_RUNTIME_UTILITY_DEVICEENVIRONMENT_CUH_

// #include <cuda_runtime.h>
#include <cstdint>
#include <string>
#include <cassert>

#ifndef __CUDACC_RTC__
namespace flamegpu_internal {
    /**
     * Defined in EnvironmentManager.cu
     */
    extern __constant__ char c_envPropBuffer[EnvironmentManager::MAX_BUFFER_SIZE];
}  // namespace flamegpu_internal
#endif

/**
 * Utility for accessing environmental properties
 * These can only be read within agent functions
 * They can be set and updated within host functions
 */
class DeviceEnvironment {
    /**
     * Constructs the object
     */
    friend class FLAMEGPU_READ_ONLY_DEVICE_API;
    /**
     * Performs runtime validation that CURVE_NAMESPACE_HASH matches host value
     */
    friend class EnvironmentManager;
    /**
     * Device accessible copy of curve namespace hash, this is precomputed from EnvironmentManager::CURVE_NAMESPACE_HASH
     * EnvironmentManager::EnvironmentManager() validates that this value matches
     */
    __host__ __device__ static constexpr unsigned int CURVE_NAMESPACE_HASH() { return 0X1428F902u; }
    /**
     * Hash of the model's name, this is added to CURVE_NAMESPACE_HASH and variable name hash to find curve hash
     */
    const Curve::NamespaceHash &modelname_hash;
    /**
     * Constructor, requires the model name hash to init modelname_hash
     * @param _modelname_hash Hash of model name generated by curveGetVariableHash()
     */
    __device__ __forceinline__ DeviceEnvironment(const Curve::NamespaceHash &_modelname_hash)
        : modelname_hash(_modelname_hash) { }

 public:
    /**
     * Gets an environment property
     * @param name name used for accessing the property, this value should be a string literal e.g. "foobar"
     * @tparam T Type of the environment property being accessed
     * @tparam N Length of variable name, this should always be implicit if passing a string literal
     */
    template<typename T, unsigned int N>
    __device__ __forceinline__ T getProperty(const char(&name)[N]) const;
    /**
     * Gets an element of an environment property array
     * @param name name used for accessing the property, this value should be a string literal e.g. "foobar"
     * @tparam T Type of the environment property being accessed
     * @tparam N Length of variable name, this should always be implicit if passing a string literal
     */
    template<typename T, unsigned int N>
    __device__ __forceinline__ T getProperty(const char(&name)[N], const unsigned int&index) const;
    /**
     * Gets an element of an environment property array
     * @param name name used for accessing the property, this value should be a string literal e.g. "foobar"
     * @tparam T Type of the environment property being accessed
     * @tparam N Length of the property array being retrieved
     * @tparam M Length of variable name, this should always be implicit if passing a string literal
     */
    template<typename T, unsigned int N, unsigned int M>
    __device__ __forceinline__ std::array<T, N> getProperty(const char(&name)[M]) const;
    /**
     * Returns whether the named env property exists
     * @param name name used for accessing the property, this value should be a string literal e.g. "foobar"
     * @tparam N Length of variable name, this should always be implicit if passing a string literal
     * @note Use of this function is not recommended as it should be unnecessary
     */
    template<unsigned int N>
    __device__ __forceinline__ bool containsProperty(const char(&name)[N]) const;
};

// Mash compilation of these functions from RTC builds as this requires a dynamic implementation of the function in curve_rtc
#ifndef __CUDACC_RTC__
/**
 * Getters
 */
template<typename T, unsigned int N>
__device__ __forceinline__ T DeviceEnvironment::getProperty(const char(&name)[N]) const {
    Curve::VariableHash cvh = CURVE_NAMESPACE_HASH() + modelname_hash + Curve::variableHash(name);
    const auto cv = Curve::getVariable(cvh);
#ifndef NO_SEATBELTS
    if (cv ==  Curve::UNKNOWN_VARIABLE) {
        DTHROW("Environment property with name: %s was not found.\n", name);
    } else if (curve_internal::d_sizes[cv] != sizeof(T)) {
        DTHROW("Environment property with name: %s type size mismatch %llu != %llu.\n", name, curve_internal::d_sizes[cv], sizeof(T));
    } else {
        return *reinterpret_cast<T*>(flamegpu_internal::c_envPropBuffer + reinterpret_cast<ptrdiff_t>(curve_internal::d_variables[cv]));
    }
    return {};
#else
    return *reinterpret_cast<T*>(flamegpu_internal::c_envPropBuffer + reinterpret_cast<ptrdiff_t>(curve_internal::d_variables[cv]));
#endif
}
template<typename T, unsigned int N>
__device__ __forceinline__ T DeviceEnvironment::getProperty(const char(&name)[N], const unsigned int &index) const {
    Curve::VariableHash cvh = CURVE_NAMESPACE_HASH() + modelname_hash + Curve::variableHash(name);
    const auto cv = Curve::getVariable(cvh);
#ifndef NO_SEATBELTS
    if (cv ==  Curve::UNKNOWN_VARIABLE) {
        DTHROW("Environment property array with name: %s was not found.\n", name);
    } else if (curve_internal::d_sizes[cv] != sizeof(T)) {
        DTHROW("Environment property array with name: %s type size mismatch %llu != %llu.\n", name, curve_internal::d_sizes[cv], sizeof(T));
    } else if (curve_internal::d_lengths[cv] <= index) {
        DTHROW("Environment property array with name: %s index %u is out of bounds (length %u).\n", name, index, curve_internal::d_lengths[cv]);
    } else {
        return *(reinterpret_cast<T*>(flamegpu_internal::c_envPropBuffer + reinterpret_cast<ptrdiff_t>(curve_internal::d_variables[cv])) + index);
    }
    return {};
#else
    return *(reinterpret_cast<T*>(flamegpu_internal::c_envPropBuffer + reinterpret_cast<ptrdiff_t>(curve_internal::d_variables[cv])) + index);
#endif
}
template<typename T, unsigned int N, unsigned int M>
__device__ __forceinline__ std::array<T, N> DeviceEnvironment::getProperty(const char(&name)[M]) const {
    Curve::VariableHash cvh = CURVE_NAMESPACE_HASH() + modelname_hash + Curve::variableHash(name);
    const auto cv = Curve::getVariable(cvh);
#ifndef NO_SEATBELTS
    if (cv == Curve::UNKNOWN_VARIABLE) {
        DTHROW("Environment property array with name: %s was not found.\n", name);
    } else if (curve_internal::d_sizes[cv] != sizeof(T)) {
        DTHROW("Environment property array with name: %s type size mismatch %llu != %llu.\n", name, curve_internal::d_sizes[cv], sizeof(T));
    } else if (curve_internal::d_lengths[cv] != N) {
        DTHROW("Environment property array with name: %s length mismatch %u != %u).\n", name, curve_internal::d_lengths[cv], N);
    } else {
        return *reinterpret_cast<std::array<T, N>*>(flamegpu_internal::c_envPropBuffer + reinterpret_cast<ptrdiff_t>(curve_internal::d_variables[cv]));
    }
    return {};
#else
    return *reinterpret_cast<T*>(flamegpu_internal::c_envPropBuffer + reinterpret_cast<ptrdiff_t>(curve_internal::d_variables[cv]));
#endif
}

/**
 * Util
 */
template<unsigned int N>
__device__ __forceinline__ bool DeviceEnvironment::containsProperty(const char(&name)[N]) const {
    Curve::VariableHash cvh = CURVE_NAMESPACE_HASH() + modelname_hash + Curve::variableHash(name);
    return Curve::getVariable(cvh) != Curve::UNKNOWN_VARIABLE;
}

#endif  // __CUDACC_RTC__

#endif  // INCLUDE_FLAMEGPU_RUNTIME_UTILITY_DEVICEENVIRONMENT_CUH_

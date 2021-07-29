#ifndef INCLUDE_FLAMEGPU_GPU_CUDAENSEMBLE_H_
#define INCLUDE_FLAMEGPU_GPU_CUDAENSEMBLE_H_

#include <string>
#include <memory>
#include <set>
#include <vector>


namespace flamegpu {

struct ModelData;
class ModelDescription;
class RunPlanVector;
class LoggingConfig;
class StepLoggingConfig;
struct RunLog;
/**
 * Manager for automatically executing multiple copies of a model simultaneously
 * This can be used to conveniently execute parameter sweeps and batch validation runs
 */
class CUDAEnsemble {
 public:
    /**
     * Execution config for running a CUDAEnsemble
     */
    struct EnsembleConfig {
        // std::string in = "";
        /**
         * Directory to store output data (primarily logs)
         */
        std::string out_directory = "";
        /**
         * Output format
         * This must be a supported format e.g.: "json" or "xml"
         */
        std::string out_format = "json";
        /**
         * The maximum number of concurrent runs
         */
        unsigned int concurrent_runs = 4;
        /**
         * The CUDA device ids of devices to be used
         * If this is left empty, all available devices will be used
         */
        std::set<int> devices;
        /**
         * If true progress logging to stdout will be suppressed
         */
        bool quiet = false;
        /**
         * If true, the total runtime for the ensemble will be printed to stdout at completion
         * This is independent of the EnsembleConfig::quiet
         */
        bool timing = false;
    };
    /**
     * Initialise CUDA Ensemble
     * If provided, you can pass runtime arguments to this constructor, to automatically call initialise()
     * This is not required, you can call initialise() manually later, or not at all.
     * @param model The model description to initialise the runner to execute
     * @param argc Runtime argument count
     * @param argv Runtime argument list ptr
     */
    explicit CUDAEnsemble(const ModelDescription& model, int argc = 0, const char** argv = nullptr);
    /**
     * Inverse operation of constructor
     */
    ~CUDAEnsemble();

    /**
     * Execute the ensemble of simulations.
     * This call will block until all simulations have completed or MAX_ERRORS simulations exit with an error
     * @param plan The plan of individual runs to execute during the ensemble
     */
    void simulate(const RunPlanVector &plan);

    /**
     * @return A mutable reference to the ensemble configuration struct
     * @see CUDAEnsemble::applyConfig() Should be called afterwards to apply changes
     */
    EnsembleConfig &Config() { return config; }
    /**
     * @return An immutable reference to the ensemble configuration struct
     */
    const EnsembleConfig &getConfig() const { return config; }
    /*
     * Override current config with args passed via CLI
     * @note Config values not passed via CLI will remain as their current values (and not be reset to default)
     */
    void initialise(int argc, const char** argv);
    /**
     * Configure which step data should be logged
     * @param stepConfig The step logging config for the CUDAEnsemble
     * @note This must be for the same model description hierarchy as the CUDAEnsemble
     */
    void setStepLog(const StepLoggingConfig &stepConfig);
    /**
     * Configure which exit data should be logged
     * @param exitConfig The logging config for the CUDAEnsemble
     * @note This must be for the same model description hierarchy as the CUDAEnsemble
     */
    void setExitLog(const LoggingConfig &exitConfig);
    /**
     * Get the duration of the last call to simulate() in milliseconds. 
     */
    float getEnsembleElapsedTime() const { return ensemble_elapsed_time; }
    /**
     * Return the list of logs collected from the last call to simulate()
     */
    const std::vector<RunLog> &getLogs();

 private:
    /**
     * Print command line interface help
     */
    void printHelp(const char *executable);
    /**
     * Parse CLI into config
     */
    int checkArgs(int argc, const char** argv);
    /**
     * Config options for the ensemble
     */
    EnsembleConfig config;
    /**
     * Step logging config
     */
    std::shared_ptr<const StepLoggingConfig> step_log_config;
    /**
     * Exit logging config
     */
    std::shared_ptr<const LoggingConfig> exit_log_config;
    /**
     * Logs collected by simulate()
     */
    std::vector<RunLog> run_logs;
    /**
     * Model description hierarchy for the ensemble, a copy of this will be passed to every CUDASimulation
     */
    const std::shared_ptr<const ModelData> model;
    /**
     * Runtime of previous call to simulate() in milliseconds, initially 0
     */
    float ensemble_elapsed_time = 0.f;
};

}  // namespace flamegpu

#endif  // INCLUDE_FLAMEGPU_GPU_CUDAENSEMBLE_H_

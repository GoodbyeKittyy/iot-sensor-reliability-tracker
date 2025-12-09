#include <iostream>
#include <vector>
#include <cmath>
#include <string>
#include <algorithm>
#include <random>
#include <iomanip>
#include <memory>

// Forward declarations
class Sensor;
class ExponentialModel;
class ErlangModel;
class QueueingModel;

// Sensor Type Enumeration
enum class SensorType {
    TRAFFIC,
    AIR_QUALITY,
    WATER_FLOW
};

// Location Structure
struct Location {
    double x, y, z;
    
    Location(double x_ = 0.0, double y_ = 0.0, double z_ = 0.0) 
        : x(x_), y(y_), z(z_) {}
};

// Sensor Class
class Sensor {
private:
    std::string id;
    SensorType type;
    Location location;
    double health;
    double uptimeHours;
    double failureRate;
    int kStages;
    int queuePosition;

public:
    Sensor(const std::string& id_, SensorType type_, const Location& loc,
           double health_, double uptime, double rate, int k, int qPos)
        : id(id_), type(type_), location(loc), health(health_),
          uptimeHours(uptime), failureRate(rate), kStages(k), 
          queuePosition(qPos) {}
    
    const std::string& getId() const { return id; }
    SensorType getType() const { return type; }
    const Location& getLocation() const { return location; }
    double getHealth() const { return health; }
    double getUptime() const { return uptimeHours; }
    double getFailureRate() const { return failureRate; }
    int getKStages() const { return kStages; }
    int getQueuePosition() const { return queuePosition; }
    
    void setHealth(double h) { health = h; }
    
    std::string getTypeString() const {
        switch(type) {
            case SensorType::TRAFFIC: return "TRAFFIC";
            case SensorType::AIR_QUALITY: return "AIR_QUALITY";
            case SensorType::WATER_FLOW: return "WATER_FLOW";
            default: return "UNKNOWN";
        }
    }
};

// Exponential Distribution Model
class ExponentialModel {
private:
    double lambda;

public:
    explicit ExponentialModel(double rate) : lambda(rate) {}
    
    double reliability(double t) const {
        return std::exp(-lambda * t);
    }
    
    double hazardRate() const {
        return lambda;
    }
    
    double mtbf() const {
        return 1.0 / lambda;
    }
    
    double pdf(double t) const {
        return lambda * std::exp(-lambda * t);
    }
};

// Erlang Distribution Model
class ErlangModel {
private:
    int k;
    double lambda;
    
    double factorial(int n) const {
        double result = 1.0;
        for(int i = 2; i <= n; ++i) {
            result *= i;
        }
        return result;
    }

public:
    ErlangModel(int stages, double rate) : k(stages), lambda(rate) {}
    
    double reliability(double t) const {
        // R(t) = 1 - CDF(t)
        double cdf = 0.0;
        double term = std::exp(-lambda * t);
        
        for(int i = 0; i < k; ++i) {
            if(i > 0) {
                term *= (lambda * t) / i;
            }
            cdf += term;
        }
        
        return 1.0 - cdf;
    }
    
    double pdf(double t) const {
        return (std::pow(lambda, k) * std::pow(t, k - 1) * 
                std::exp(-lambda * t)) / factorial(k - 1);
    }
    
    double mttf() const {
        return static_cast<double>(k) / lambda;
    }
};

// Queueing Theory M/M/c Model
class QueueingModel {
private:
    double arrivalRate;
    double serviceRate;
    int numServers;
    double rho;
    
    double factorial(int n) const {
        double result = 1.0;
        for(int i = 2; i <= n; ++i) {
            result *= i;
        }
        return result;
    }
    
    double calculateP0() const {
        double lambdaMu = arrivalRate / serviceRate;
        double sumTerm = 0.0;
        
        for(int n = 0; n < numServers; ++n) {
            sumTerm += std::pow(lambdaMu, n) / factorial(n);
        }
        
        double lastTerm = std::pow(lambdaMu, numServers) / 
                         (factorial(numServers) * (1.0 - rho));
        
        return 1.0 / (sumTerm + lastTerm);
    }

public:
    QueueingModel(double arrival, double service, int servers)
        : arrivalRate(arrival), serviceRate(service), numServers(servers) {
        rho = arrivalRate / (numServers * serviceRate);
    }
    
    bool isStable() const {
        return rho < 1.0;
    }
    
    double getUtilization() const {
        return rho;
    }
    
    double avgQueueLength() const {
        if(!isStable()) return -1.0;
        
        double p0 = calculateP0();
        double lambdaMu = arrivalRate / serviceRate;
        
        return (p0 * std::pow(lambdaMu, numServers) * rho) /
               (factorial(numServers) * std::pow(1.0 - rho, 2));
    }
    
    double avgWaitTime() const {
        if(!isStable()) return -1.0;
        
        double lq = avgQueueLength();
        return (arrivalRate > 0) ? lq / arrivalRate : 0.0;
    }
};

// Fleet Reliability Manager
class FleetReliabilityManager {
private:
    std::vector<std::shared_ptr<Sensor>> sensors;
    std::vector<std::unique_ptr<ExponentialModel>> exponentialModels;
    std::vector<std::unique_ptr<ErlangModel>> erlangModels;

public:
    void addSensor(std::shared_ptr<Sensor> sensor) {
        sensors.push_back(sensor);
        
        exponentialModels.push_back(
            std::make_unique<ExponentialModel>(sensor->getFailureRate())
        );
        
        erlangModels.push_back(
            std::make_unique<ErlangModel>(sensor->getKStages(), sensor->getFailureRate())
        );
    }
    
    double calculateFleetMTBF() const {
        double sum = 0.0;
        for(const auto& model : exponentialModels) {
            sum += model->mtbf();
        }
        return sum / exponentialModels.size();
    }
    
    double calculateFleetMTTF() const {
        double sum = 0.0;
        for(const auto& model : erlangModels) {
            sum += model->mttf();
        }
        return sum / erlangModels.size();
    }
    
    double calculateFleetReliability(double timeHorizon) const {
        double sum = 0.0;
        for(const auto& model : erlangModels) {
            sum += model->reliability(timeHorizon);
        }
        return sum / erlangModels.size();
    }
    
    struct SensorStats {
        int total;
        int active;
        int warning;
        int failed;
    };
    
    SensorStats getSensorStats() const {
        SensorStats stats = {0, 0, 0, 0};
        stats.total = sensors.size();
        
        for(const auto& sensor : sensors) {
            double health = sensor->getHealth();
            if(health > 70.0) {
                stats.active++;
            } else if(health > 30.0) {
                stats.warning++;
            } else {
                stats.failed++;
            }
        }
        
        return stats;
    }
    
    struct CascadeRisk {
        int currentFailures;
        double riskFactor;
        int expectedAdditional;
        std::string riskLevel;
        double dependencyMultiplier;
    };
    
    CascadeRisk analyzeCascadeRisk() const {
        CascadeRisk risk;
        risk.currentFailures = 0;
        
        for(const auto& sensor : sensors) {
            if(sensor->getHealth() < 30.0) {
                risk.currentFailures++;
            }
        }
        
        risk.riskFactor = static_cast<double>(risk.currentFailures) / sensors.size();
        
        if(risk.riskFactor > 0.2) {
            risk.dependencyMultiplier = 1.5;
        } else if(risk.riskFactor > 0.1) {
            risk.dependencyMultiplier = 1.2;
        } else {
            risk.dependencyMultiplier = 1.0;
        }
        
        risk.expectedAdditional = static_cast<int>(
            risk.currentFailures * risk.dependencyMultiplier * 0.3
        );
        
        if(risk.riskFactor > 0.15) {
            risk.riskLevel = "HIGH";
        } else if(risk.riskFactor > 0.08) {
            risk.riskLevel = "MEDIUM";
        } else {
            risk.riskLevel = "LOW";
        }
        
        return risk;
    }
    
    const std::vector<std::shared_ptr<Sensor>>& getSensors() const {
        return sensors;
    }
};

// Initialize sample sensor network
void initializeSensorNetwork(FleetReliabilityManager& manager) {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<> locDist(5.0, 95.0);
    std::uniform_real_distribution<> healthDist(20.0, 100.0);
    std::uniform_real_distribution<> rateDist(0.0003, 0.0008);
    std::uniform_int_distribution<> kDist(2, 5);
    std::uniform_int_distribution<> queueDist(0, 9);
    
    std::vector<SensorType> types = {
        SensorType::TRAFFIC, 
        SensorType::AIR_QUALITY, 
        SensorType::WATER_FLOW
    };
    
    for(int i = 0; i < 50; ++i) {
        std::string id = "SNS-" + std::string(4 - std::to_string(i+1).length(), '0') + 
                        std::to_string(i+1);
        
        Location loc(locDist(gen), locDist(gen), locDist(gen) / 30.0);
        
        auto sensor = std::make_shared<Sensor>(
            id,
            types[i % 3],
            loc,
            healthDist(gen),
            1000.0 + i * 100.0,
            rateDist(gen),
            kDist(gen),
            queueDist(gen)
        );
        
        manager.addSensor(sensor);
    }
}

// Main program
int main() {
    std::cout << "=================================================" << std::endl;
    std::cout << "IoT Sensor Network Reliability Tracker - C++" << std::endl;
    std::cout << "=================================================" << std::endl;
    std::cout << std::endl;
    
    // Initialize fleet manager
    FleetReliabilityManager manager;
    initializeSensorNetwork(manager);
    
    // Calculate fleet metrics
    std::cout << "=== Fleet Reliability Metrics ===" << std::endl;
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Fleet MTBF: " << manager.calculateFleetMTBF() << " hours" << std::endl;
    std::cout << "Fleet MTTF: " << manager.calculateFleetMTTF() << " hours" << std::endl;
    std::cout << "Fleet Reliability (1000h): " 
              << manager.calculateFleetReliability(1000.0) * 100.0 << "%" << std::endl;
    std::cout << std::endl;
    
    // Sensor statistics
    auto stats = manager.getSensorStats();
    std::cout << "=== Sensor Statistics ===" << std::endl;
    std::cout << "Total Sensors: " << stats.total << std::endl;
    std::cout << "Active (>70%): " << stats.active << std::endl;
    std::cout << "Warning (30-70%): " << stats.warning << std::endl;
    std::cout << "Failed (<30%): " << stats.failed << std::endl;
    std::cout << std::endl;
    
    // Queueing analysis
    QueueingModel queue(0.05, 0.15, 3);
    std::cout << "=== Maintenance Queue Analysis (M/M/3) ===" << std::endl;
    if(queue.isStable()) {
        std::cout << "System Utilization: " 
                  << queue.getUtilization() * 100.0 << "%" << std::endl;
        std::cout << "Average Queue Length: " 
                  << queue.avgQueueLength() << std::endl;
        std::cout << "Average Wait Time: " 
                  << queue.avgWaitTime() * 60.0 << " minutes" << std::endl;
    } else {
        std::cout << "Queue system unstable (rho >= 1)" << std::endl;
    }
    std::cout << std::endl;
    
    // Cascade risk analysis
    auto cascade = manager.analyzeCascadeRisk();
    std::cout << "=== Cascade Failure Risk ===" << std::endl;
    std::cout << "Current Failures: " << cascade.currentFailures << std::endl;
    std::cout << std::setprecision(3);
    std::cout << "Cascade Risk Factor: " << cascade.riskFactor << std::endl;
    std::cout << "Expected Additional Failures: " 
              << cascade.expectedAdditional << std::endl;
    std::cout << "Risk Level: " << cascade.riskLevel << std::endl;
    std::cout << std::endl;
    
    // Sample sensor analysis
    auto sensors = manager.getSensors();
    if(!sensors.empty()) {
        auto sensor = sensors[0];
        ExponentialModel expModel(sensor->getFailureRate());
        ErlangModel erlModel(sensor->getKStages(), sensor->getFailureRate());
        
        std::cout << "=== Sample Sensor Analysis ===" << std::endl;
        std::cout << "Sensor ID: " << sensor->getId() << std::endl;
        std::cout << "Type: " << sensor->getTypeString() << std::endl;
        std::cout << std::setprecision(4);
        std::cout << "Exponential R(500h): " 
                  << expModel.reliability(500.0) << std::endl;
        std::cout << "Erlang R(500h): " 
                  << erlModel.reliability(500.0) << std::endl;
        std::cout << std::setprecision(2);
        std::cout << "MTBF: " << expModel.mtbf() << " hours" << std::endl;
        std::cout << "MTTF: " << erlModel.mttf() << " hours" << std::endl;
        std::cout << std::endl;
    }
    
    std::cout << "=== Analysis Complete ===" << std::endl;
    
    return 0;
}

import numpy as np
import pandas as pd
from scipy import stats
from dataclasses import dataclass
from typing import List, Tuple, Dict
import json
from datetime import datetime, timedelta


@dataclass
class Sensor:
    id: str
    sensor_type: str
    location: Tuple[float, float, float]
    installation_date: datetime
    failure_rate: float
    k_stages: int
    current_health: float
    uptime_hours: float
    maintenance_queue_position: int


class ExponentialFailureModel:
    """Models sensor failures using exponential distribution (memoryless property)"""
    
    def __init__(self, lambda_rate: float):
        self.lambda_rate = lambda_rate
        self.distribution = stats.expon(scale=1/lambda_rate)
    
    def time_to_failure(self) -> float:
        """Generate time to next failure"""
        return self.distribution.rvs()
    
    def reliability_at_time(self, t: float) -> float:
        """Calculate reliability R(t) = e^(-λt)"""
        return np.exp(-self.lambda_rate * t)
    
    def hazard_rate(self) -> float:
        """Constant hazard rate for exponential distribution"""
        return self.lambda_rate
    
    def mtbf(self) -> float:
        """Mean Time Between Failures"""
        return 1 / self.lambda_rate


class ErlangFailureModel:
    """Models multi-stage component failures using Erlang distribution"""
    
    def __init__(self, k: int, lambda_rate: float):
        self.k = k
        self.lambda_rate = lambda_rate
        self.distribution = stats.erlang(k, scale=1/lambda_rate)
    
    def time_to_failure(self) -> float:
        """Generate time to failure through k stages"""
        return self.distribution.rvs()
    
    def reliability_at_time(self, t: float) -> float:
        """Calculate reliability for Erlang distribution"""
        return 1 - self.distribution.cdf(t)
    
    def pdf(self, t: float) -> float:
        """Probability density function"""
        return self.distribution.pdf(t)
    
    def mttf(self) -> float:
        """Mean Time To Failure for k-stage system"""
        return self.k / self.lambda_rate


class QueueingTheoryModel:
    """M/M/c queueing model for maintenance crew optimization"""
    
    def __init__(self, arrival_rate: float, service_rate: float, num_servers: int):
        self.arrival_rate = arrival_rate
        self.service_rate = service_rate
        self.num_servers = num_servers
        self.rho = arrival_rate / (num_servers * service_rate)
    
    def average_queue_length(self) -> float:
        """Calculate Lq using M/M/c formula"""
        if self.rho >= 1:
            return float('inf')
        
        c = self.num_servers
        rho = self.rho
        lam = self.arrival_rate
        mu = self.service_rate
        
        p0 = self._calculate_p0()
        
        lq = (p0 * (lam/mu)**c * rho) / (np.math.factorial(c) * (1 - rho)**2)
        return lq
    
    def _calculate_p0(self) -> float:
        """Calculate probability of zero customers in system"""
        c = self.num_servers
        lam = self.arrival_rate
        mu = self.service_rate
        rho = lam / mu
        
        sum_term = sum((rho**n) / np.math.factorial(n) for n in range(c))
        last_term = (rho**c) / (np.math.factorial(c) * (1 - self.rho))
        
        return 1 / (sum_term + last_term)
    
    def average_waiting_time(self) -> float:
        """Calculate Wq using Little's Law"""
        lq = self.average_queue_length()
        return lq / self.arrival_rate if self.arrival_rate > 0 else 0
    
    def system_utilization(self) -> float:
        """Calculate server utilization"""
        return self.rho


class SensorNetworkReliability:
    """Main reliability analysis engine for IoT sensor network"""
    
    def __init__(self):
        self.sensors: List[Sensor] = []
        self.exponential_models: Dict[str, ExponentialFailureModel] = {}
        self.erlang_models: Dict[str, ErlangFailureModel] = {}
        self.maintenance_queue = QueueingTheoryModel(
            arrival_rate=0.05,
            service_rate=0.15,
            num_servers=3
        )
    
    def add_sensor(self, sensor: Sensor):
        """Add sensor to network and create failure models"""
        self.sensors.append(sensor)
        
        self.exponential_models[sensor.id] = ExponentialFailureModel(
            lambda_rate=sensor.failure_rate
        )
        
        self.erlang_models[sensor.id] = ErlangFailureModel(
            k=sensor.k_stages,
            lambda_rate=sensor.failure_rate
        )
    
    def calculate_fleet_mtbf(self) -> float:
        """Calculate fleet-wide Mean Time Between Failures"""
        mtbf_values = [
            self.exponential_models[s.id].mtbf() 
            for s in self.sensors
        ]
        return np.mean(mtbf_values)
    
    def calculate_fleet_mttf(self) -> float:
        """Calculate fleet-wide Mean Time To Failure (Erlang)"""
        mttf_values = [
            self.erlang_models[s.id].mttf() 
            for s in self.sensors
        ]
        return np.mean(mttf_values)
    
    def calculate_fleet_reliability(self, time_horizon: float = 1000) -> float:
        """Calculate overall fleet reliability at time t"""
        reliabilities = [
            self.erlang_models[s.id].reliability_at_time(time_horizon)
            for s in self.sensors
        ]
        return np.mean(reliabilities)
    
    def predict_cascade_failures(self, failed_sensor_ids: List[str]) -> Dict:
        """Predict cascade failure probability using dependency graph"""
        cascade_risk = len(failed_sensor_ids) / len(self.sensors)
        
        dependency_multiplier = 1.0
        if cascade_risk > 0.2:
            dependency_multiplier = 1.5
        elif cascade_risk > 0.1:
            dependency_multiplier = 1.2
        
        expected_additional_failures = int(
            len(failed_sensor_ids) * dependency_multiplier * 0.3
        )
        
        risk_level = "LOW"
        if cascade_risk > 0.15:
            risk_level = "HIGH"
        elif cascade_risk > 0.08:
            risk_level = "MEDIUM"
        
        return {
            "current_failures": len(failed_sensor_ids),
            "cascade_risk_factor": cascade_risk,
            "expected_additional_failures": expected_additional_failures,
            "risk_level": risk_level,
            "dependency_multiplier": dependency_multiplier
        }
    
    def optimize_maintenance_routing(self) -> List[Dict]:
        """Generate optimized technician routing schedule"""
        failed_sensors = [s for s in self.sensors if s.current_health < 30]
        warning_sensors = [s for s in self.sensors if 30 <= s.current_health <= 70]
        
        failed_sensors.sort(key=lambda s: s.maintenance_queue_position)
        warning_sensors.sort(key=lambda s: s.current_health)
        
        schedule = []
        crews = ["CREW-A", "CREW-B", "CREW-C"]
        
        all_priority_sensors = failed_sensors + warning_sensors[:10]
        
        for idx, sensor in enumerate(all_priority_sensors):
            crew = crews[idx % len(crews)]
            estimated_time = (idx // len(crews)) * 45 + np.random.randint(10, 30)
            
            schedule.append({
                "sensor_id": sensor.id,
                "sensor_type": sensor.sensor_type,
                "location": sensor.location,
                "health": sensor.current_health,
                "assigned_crew": crew,
                "priority": 1 if sensor.current_health < 30 else 2,
                "estimated_arrival_minutes": estimated_time,
                "estimated_repair_time_minutes": 60 if sensor.current_health < 30 else 30
            })
        
        return schedule
    
    def generate_replacement_schedule(self, cost_per_replacement: float = 5000) -> pd.DataFrame:
        """Generate optimized replacement schedule minimizing TCO"""
        replacement_data = []
        
        for sensor in self.sensors:
            erlang_model = self.erlang_models[sensor.id]
            expected_failure_time = erlang_model.mttf()
            
            remaining_life = expected_failure_time - sensor.uptime_hours
            
            if remaining_life < 500:
                urgency = "CRITICAL"
                scheduled_date = datetime.now() + timedelta(days=7)
            elif remaining_life < 1000:
                urgency = "HIGH"
                scheduled_date = datetime.now() + timedelta(days=30)
            elif remaining_life < 2000:
                urgency = "MEDIUM"
                scheduled_date = datetime.now() + timedelta(days=90)
            else:
                urgency = "LOW"
                scheduled_date = datetime.now() + timedelta(days=180)
            
            replacement_data.append({
                "sensor_id": sensor.id,
                "sensor_type": sensor.sensor_type,
                "current_health": sensor.current_health,
                "uptime_hours": sensor.uptime_hours,
                "expected_remaining_life_hours": max(0, remaining_life),
                "urgency": urgency,
                "scheduled_replacement_date": scheduled_date.strftime("%Y-%m-%d"),
                "estimated_cost": cost_per_replacement,
                "failure_probability_30d": 1 - erlang_model.reliability_at_time(sensor.uptime_hours + 720)
            })
        
        df = pd.DataFrame(replacement_data)
        df = df.sort_values("expected_remaining_life_hours")
        
        return df
    
    def get_network_statistics(self) -> Dict:
        """Generate comprehensive network statistics"""
        active_sensors = [s for s in self.sensors if s.current_health > 70]
        warning_sensors = [s for s in self.sensors if 30 <= s.current_health <= 70]
        failed_sensors = [s for s in self.sensors if s.current_health < 30]
        
        return {
            "total_sensors": len(self.sensors),
            "active_sensors": len(active_sensors),
            "warning_sensors": len(warning_sensors),
            "failed_sensors": len(failed_sensors),
            "fleet_mtbf_hours": self.calculate_fleet_mtbf(),
            "fleet_mttf_hours": self.calculate_fleet_mttf(),
            "fleet_reliability_percent": self.calculate_fleet_reliability() * 100,
            "average_queue_wait_minutes": self.maintenance_queue.average_waiting_time() * 60,
            "maintenance_utilization_percent": self.maintenance_queue.system_utilization() * 100,
            "cascade_risk": self.predict_cascade_failures([s.id for s in failed_sensors])
        }
    
    def export_sensor_data(self, filename: str = "sensor_data.json"):
        """Export all sensor data to JSON"""
        data = {
            "export_timestamp": datetime.now().isoformat(),
            "network_statistics": self.get_network_statistics(),
            "sensors": [
                {
                    "id": s.id,
                    "type": s.sensor_type,
                    "location": {
                        "x": s.location[0],
                        "y": s.location[1],
                        "z": s.location[2]
                    },
                    "health": s.current_health,
                    "uptime_hours": s.uptime_hours,
                    "failure_rate": s.failure_rate,
                    "k_stages": s.k_stages,
                    "mtbf": self.exponential_models[s.id].mtbf(),
                    "mttf": self.erlang_models[s.id].mttf()
                }
                for s in self.sensors
            ]
        }
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        
        return data


def initialize_sample_network() -> SensorNetworkReliability:
    """Initialize sample IoT sensor network for demonstration"""
    network = SensorNetworkReliability()
    
    sensor_types = ["TRAFFIC", "AIR_QUALITY", "WATER_FLOW"]
    
    for i in range(50):
        sensor = Sensor(
            id=f"SNS-{str(i+1).zfill(4)}",
            sensor_type=sensor_types[i % 3],
            location=(
                np.random.uniform(5, 95),
                np.random.uniform(5, 95),
                np.random.uniform(0, 3)
            ),
            installation_date=datetime.now() - timedelta(days=np.random.randint(30, 1000)),
            failure_rate=np.random.uniform(0.0003, 0.0008),
            k_stages=np.random.randint(2, 5),
            current_health=np.random.uniform(20, 100),
            uptime_hours=np.random.uniform(100, 8000),
            maintenance_queue_position=np.random.randint(0, 10)
        )
        network.add_sensor(sensor)
    
    return network


if __name__ == "__main__":
    print("IoT Sensor Network Reliability Tracker - Initializing...")
    
    network = initialize_sample_network()
    
    print("\n=== NETWORK STATISTICS ===")
    stats = network.get_network_statistics()
    for key, value in stats.items():
        if isinstance(value, float):
            print(f"{key}: {value:.2f}")
        else:
            print(f"{key}: {value}")
    
    print("\n=== MAINTENANCE ROUTING OPTIMIZATION ===")
    routing = network.optimize_maintenance_routing()
    print(f"Generated {len(routing)} maintenance tasks")
    for task in routing[:5]:
        print(f"  {task['sensor_id']} -> {task['assigned_crew']} (ETA: {task['estimated_arrival_minutes']} min)")
    
    print("\n=== REPLACEMENT SCHEDULE ===")
    schedule_df = network.generate_replacement_schedule()
    print(schedule_df.head(10))
    
    print("\n=== EXPORTING DATA ===")
    network.export_sensor_data()
    print("Data exported to sensor_data.json")
    
    print("\n=== RELIABILITY ANALYSIS COMPLETE ===")

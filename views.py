from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import json
import numpy as np
from datetime import datetime, timedelta
from scipy import stats


class SensorManager:
    """Django-integrated sensor management system"""
    
    def __init__(self):
        self.sensors = self._initialize_sensors()
    
    def _initialize_sensors(self):
        """Initialize sensor database"""
        sensors = []
        sensor_types = ["TRAFFIC", "AIR_QUALITY", "WATER_FLOW"]
        
        for i in range(50):
            sensors.append({
                "id": f"SNS-{str(i+1).zfill(4)}",
                "type": sensor_types[i % 3],
                "location": {
                    "x": float(np.random.uniform(5, 95)),
                    "y": float(np.random.uniform(5, 95)),
                    "z": float(np.random.uniform(0, 3))
                },
                "health": float(np.random.uniform(20, 100)),
                "uptime_hours": float(np.random.uniform(100, 8000)),
                "failure_rate": float(np.random.uniform(0.0003, 0.0008)),
                "k_stages": int(np.random.randint(2, 5)),
                "next_failure_estimate": float(np.random.uniform(100, 2000)),
                "queue_position": int(np.random.randint(0, 10)),
                "last_maintenance": (datetime.now() - timedelta(days=np.random.randint(1, 180))).isoformat()
            })
        
        return sensors
    
    def get_all_sensors(self):
        """Return all sensors"""
        return self.sensors
    
    def get_sensor_by_id(self, sensor_id):
        """Get specific sensor by ID"""
        for sensor in self.sensors:
            if sensor["id"] == sensor_id:
                return sensor
        return None
    
    def update_sensor_health(self, sensor_id, new_health):
        """Update sensor health status"""
        for sensor in self.sensors:
            if sensor["id"] == sensor_id:
                sensor["health"] = new_health
                return True
        return False
    
    def calculate_reliability_metrics(self):
        """Calculate fleet-wide reliability metrics"""
        total = len(self.sensors)
        active = sum(1 for s in self.sensors if s["health"] > 70)
        warning = sum(1 for s in self.sensors if 30 <= s["health"] <= 70)
        failed = sum(1 for s in self.sensors if s["health"] < 30)
        
        failure_rates = [s["failure_rate"] for s in self.sensors]
        mtbf = 1 / np.mean(failure_rates)
        
        k_values = [s["k_stages"] for s in self.sensors]
        mttf = np.mean(k_values) / np.mean(failure_rates)
        
        reliabilities = []
        for sensor in self.sensors:
            k = sensor["k_stages"]
            lam = sensor["failure_rate"]
            t = 1000
            erlang_dist = stats.erlang(k, scale=1/lam)
            reliability = 1 - erlang_dist.cdf(t)
            reliabilities.append(reliability)
        
        fleet_reliability = np.mean(reliabilities) * 100
        
        return {
            "total_sensors": total,
            "active_sensors": active,
            "warning_sensors": warning,
            "failed_sensors": failed,
            "fleet_mtbf_hours": float(mtbf),
            "fleet_mttf_hours": float(mttf),
            "fleet_reliability_percent": float(fleet_reliability),
            "cascade_risk_level": "LOW" if failed < 5 else "MEDIUM" if failed < 10 else "HIGH"
        }
    
    def generate_maintenance_schedule(self):
        """Generate maintenance crew routing schedule"""
        failed_sensors = [s for s in self.sensors if s["health"] < 30]
        warning_sensors = [s for s in self.sensors if 30 <= s["health"] <= 70]
        
        failed_sensors.sort(key=lambda x: x["queue_position"])
        warning_sensors.sort(key=lambda x: x["health"])
        
        priority_sensors = failed_sensors + warning_sensors[:10]
        
        crews = ["CREW-A", "CREW-B", "CREW-C"]
        schedule = []
        
        for idx, sensor in enumerate(priority_sensors):
            crew = crews[idx % len(crews)]
            eta = (idx // len(crews)) * 45 + np.random.randint(10, 30)
            
            schedule.append({
                "sensor_id": sensor["id"],
                "sensor_type": sensor["type"],
                "location": sensor["location"],
                "health": sensor["health"],
                "assigned_crew": crew,
                "priority": 1 if sensor["health"] < 30 else 2,
                "eta_minutes": int(eta),
                "repair_time_minutes": 60 if sensor["health"] < 30 else 30
            })
        
        return schedule
    
    def get_crew_status(self):
        """Get maintenance crew status"""
        schedule = self.generate_maintenance_schedule()
        
        crews = {
            "CREW-A": {"assigned": 0, "location": "SECTOR-NE", "eta": 0},
            "CREW-B": {"assigned": 0, "location": "SECTOR-SW", "eta": 0},
            "CREW-C": {"assigned": 0, "location": "BASE", "eta": 0}
        }
        
        for task in schedule:
            crew_id = task["assigned_crew"]
            crews[crew_id]["assigned"] += 1
            if crews[crew_id]["eta"] == 0:
                crews[crew_id]["eta"] = task["eta_minutes"]
        
        return [
            {"id": crew_id, **crew_data}
            for crew_id, crew_data in crews.items()
        ]
    
    def calculate_queueing_metrics(self):
        """Calculate queueing theory metrics for maintenance"""
        arrival_rate = 0.05
        service_rate = 0.15
        num_servers = 3
        
        rho = arrival_rate / (num_servers * service_rate)
        utilization = rho * 100
        
        c = num_servers
        lam_mu = arrival_rate / service_rate
        
        p0_denominator = sum((lam_mu**n) / np.math.factorial(n) for n in range(c))
        p0_denominator += (lam_mu**c) / (np.math.factorial(c) * (1 - rho))
        p0 = 1 / p0_denominator
        
        lq = (p0 * (lam_mu)**c * rho) / (np.math.factorial(c) * (1 - rho)**2)
        
        wq = lq / arrival_rate if arrival_rate > 0 else 0
        wq_minutes = wq * 60
        
        return {
            "average_queue_length": float(lq),
            "average_wait_minutes": float(wq_minutes),
            "system_utilization_percent": float(utilization)
        }


sensor_manager = SensorManager()


@csrf_exempt
@require_http_methods(["GET"])
def api_sensors_list(request):
    """GET /api/sensors/ - List all sensors"""
    sensors = sensor_manager.get_all_sensors()
    return JsonResponse({"sensors": sensors, "count": len(sensors)})


@csrf_exempt
@require_http_methods(["GET"])
def api_sensor_detail(request, sensor_id):
    """GET /api/sensors/<id>/ - Get specific sensor"""
    sensor = sensor_manager.get_sensor_by_id(sensor_id)
    
    if sensor:
        return JsonResponse({"sensor": sensor})
    else:
        return JsonResponse({"error": "Sensor not found"}, status=404)


@csrf_exempt
@require_http_methods(["POST"])
def api_sensor_update(request, sensor_id):
    """POST /api/sensors/<id>/update/ - Update sensor health"""
    try:
        data = json.loads(request.body)
        new_health = data.get("health")
        
        if new_health is None:
            return JsonResponse({"error": "Health value required"}, status=400)
        
        success = sensor_manager.update_sensor_health(sensor_id, float(new_health))
        
        if success:
            return JsonResponse({"success": True, "sensor_id": sensor_id, "new_health": new_health})
        else:
            return JsonResponse({"error": "Sensor not found"}, status=404)
    
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@require_http_methods(["GET"])
def api_reliability_metrics(request):
    """GET /api/reliability/ - Get fleet reliability metrics"""
    metrics = sensor_manager.calculate_reliability_metrics()
    queueing = sensor_manager.calculate_queueing_metrics()
    
    return JsonResponse({
        "reliability_metrics": metrics,
        "queueing_metrics": queueing,
        "timestamp": datetime.now().isoformat()
    })


@csrf_exempt
@require_http_methods(["GET"])
def api_maintenance_schedule(request):
    """GET /api/maintenance/schedule/ - Get maintenance schedule"""
    schedule = sensor_manager.generate_maintenance_schedule()
    
    return JsonResponse({
        "schedule": schedule,
        "total_tasks": len(schedule),
        "timestamp": datetime.now().isoformat()
    })


@csrf_exempt
@require_http_methods(["GET"])
def api_crew_status(request):
    """GET /api/maintenance/crews/ - Get crew status"""
    crews = sensor_manager.get_crew_status()
    
    return JsonResponse({
        "crews": crews,
        "timestamp": datetime.now().isoformat()
    })


@csrf_exempt
@require_http_methods(["GET"])
def api_analytics(request):
    """GET /api/analytics/ - Get comprehensive analytics"""
    metrics = sensor_manager.calculate_reliability_metrics()
    queueing = sensor_manager.calculate_queueing_metrics()
    
    sensors = sensor_manager.get_all_sensors()
    
    erlang_analysis = {
        "k_stage_failures_detected": len([s for s in sensors if s["k_stages"] > 2]),
        "average_k_parameter": float(np.mean([s["k_stages"] for s in sensors])),
        "average_lambda_parameter": float(np.mean([s["failure_rate"] for s in sensors]))
    }
    
    return JsonResponse({
        "reliability_metrics": metrics,
        "queueing_metrics": queueing,
        "erlang_analysis": erlang_analysis,
        "timestamp": datetime.now().isoformat()
    })


@csrf_exempt
@require_http_methods(["POST"])
def api_simulate_cascade(request):
    """POST /api/simulate/cascade/ - Simulate cascade failures"""
    try:
        data = json.loads(request.body)
        failed_sensor_ids = data.get("failed_sensors", [])
        
        sensors = sensor_manager.get_all_sensors()
        total_sensors = len(sensors)
        
        cascade_risk = len(failed_sensor_ids) / total_sensors
        
        dependency_multiplier = 1.0
        if cascade_risk > 0.2:
            dependency_multiplier = 1.5
        elif cascade_risk > 0.1:
            dependency_multiplier = 1.2
        
        expected_additional = int(len(failed_sensor_ids) * dependency_multiplier * 0.3)
        
        risk_level = "LOW"
        if cascade_risk > 0.15:
            risk_level = "HIGH"
        elif cascade_risk > 0.08:
            risk_level = "MEDIUM"
        
        return JsonResponse({
            "current_failures": len(failed_sensor_ids),
            "cascade_risk_factor": float(cascade_risk),
            "expected_additional_failures": expected_additional,
            "risk_level": risk_level,
            "dependency_multiplier": float(dependency_multiplier),
            "total_predicted_failures": len(failed_sensor_ids) + expected_additional
        })
    
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@require_http_methods(["GET"])
def api_health_check(request):
    """GET /api/health/ - API health check"""
    return JsonResponse({
        "status": "operational",
        "version": "9000.4.2",
        "timestamp": datetime.now().isoformat(),
        "endpoints": [
            "/api/sensors/",
            "/api/sensors/<id>/",
            "/api/sensors/<id>/update/",
            "/api/reliability/",
            "/api/maintenance/schedule/",
            "/api/maintenance/crews/",
            "/api/analytics/",
            "/api/simulate/cascade/",
            "/api/health/"
        ]
    })

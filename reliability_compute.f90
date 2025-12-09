! IoT Sensor Network Reliability Computation Engine in Fortran
! High-performance numerical computations for reliability theory

program iot_reliability_tracker
    implicit none
    
    integer, parameter :: dp = selected_real_kind(15, 307)
    integer, parameter :: max_sensors = 100
    integer, parameter :: max_stages = 10
    
    ! Sensor network variables
    integer :: n_sensors, i, j, k_val
    real(dp) :: lambda, time_horizon, reliability
    real(dp), dimension(max_sensors) :: failure_rates, health_values
    real(dp), dimension(max_sensors) :: mtbf_values, mttf_values
    integer, dimension(max_sensors) :: k_stages
    
    ! Fleet metrics
    real(dp) :: fleet_mtbf, fleet_mttf, fleet_reliability
    integer :: active_count, warning_count, failed_count
    
    ! Queueing parameters
    real(dp) :: arrival_rate, service_rate, utilization
    real(dp) :: avg_queue_length, avg_wait_time
    integer :: num_servers
    
    ! Initialize simulation parameters
    n_sensors = 50
    time_horizon = 1000.0_dp
    
    call initialize_sensor_network(n_sensors, failure_rates, health_values, k_stages)
    
    print *, '================================================='
    print *, 'IoT Sensor Network Reliability Tracker - Fortran'
    print *, '================================================='
    print *, ''
    
    ! Calculate MTBF for each sensor (exponential distribution)
    call calculate_mtbf_array(n_sensors, failure_rates, mtbf_values)
    
    ! Calculate MTTF for each sensor (Erlang distribution)
    call calculate_mttf_array(n_sensors, k_stages, failure_rates, mttf_values)
    
    ! Calculate fleet-wide metrics
    fleet_mtbf = sum(mtbf_values(1:n_sensors)) / real(n_sensors, dp)
    fleet_mttf = sum(mttf_values(1:n_sensors)) / real(n_sensors, dp)
    
    ! Calculate fleet reliability
    call calculate_fleet_reliability(n_sensors, k_stages, failure_rates, &
                                     time_horizon, fleet_reliability)
    
    ! Classify sensors by health
    call classify_sensors_by_health(n_sensors, health_values, &
                                     active_count, warning_count, failed_count)
    
    ! Print fleet metrics
    print *, '=== Fleet Reliability Metrics ==='
    print '(A,I4)', ' Total Sensors: ', n_sensors
    print '(A,I4)', ' Active Sensors (>70%): ', active_count
    print '(A,I4)', ' Warning Sensors (30-70%): ', warning_count
    print '(A,I4)', ' Failed Sensors (<30%): ', failed_count
    print '(A,F10.2,A)', ' Fleet MTBF: ', fleet_mtbf, ' hours'
    print '(A,F10.2,A)', ' Fleet MTTF: ', fleet_mttf, ' hours'
    print '(A,F8.4,A)', ' Fleet Reliability: ', fleet_reliability * 100.0_dp, '%'
    print *, ''
    
    ! Queueing theory analysis (M/M/c)
    arrival_rate = 0.05_dp
    service_rate = 0.15_dp
    num_servers = 3
    
    call analyze_maintenance_queue(arrival_rate, service_rate, num_servers, &
                                    utilization, avg_queue_length, avg_wait_time)
    
    print *, '=== Maintenance Queue Analysis (M/M/3) ==='
    print '(A,F8.4,A)', ' System Utilization: ', utilization * 100.0_dp, '%'
    print '(A,F8.4)', ' Average Queue Length: ', avg_queue_length
    print '(A,F8.2,A)', ' Average Wait Time: ', avg_wait_time * 60.0_dp, ' minutes'
    print *, ''
    
    ! Sample reliability calculations
    print *, '=== Sample Sensor Reliability Analysis ==='
    print *, ' Sensor ID: SNS-0001'
    lambda = failure_rates(1)
    k_val = k_stages(1)
    
    reliability = exponential_reliability(lambda, 500.0_dp)
    print '(A,F10.6)', ' Exponential R(500h): ', reliability
    
    reliability = erlang_reliability(k_val, lambda, 500.0_dp)
    print '(A,F10.6)', ' Erlang R(500h): ', reliability
    print *, ''
    
    ! Cascade failure risk
    call analyze_cascade_risk(failed_count, n_sensors)
    
    print *, '=== Computation Complete ==='
    
contains

    ! Initialize sensor network with random parameters
    subroutine initialize_sensor_network(n, rates, health, k_vals)
        integer, intent(in) :: n
        real(dp), dimension(:), intent(out) :: rates, health
        integer, dimension(:), intent(out) :: k_vals
        integer :: i
        real(dp) :: rand_val
        
        call random_seed()
        
        do i = 1, n
            call random_number(rand_val)
            rates(i) = 0.0003_dp + rand_val * 0.0005_dp
            
            call random_number(rand_val)
            health(i) = 20.0_dp + rand_val * 80.0_dp
            
            call random_number(rand_val)
            k_vals(i) = 2 + int(rand_val * 3.0_dp)
        end do
    end subroutine initialize_sensor_network
    
    ! Calculate MTBF using exponential distribution
    function exponential_mtbf(lambda) result(mtbf)
        real(dp), intent(in) :: lambda
        real(dp) :: mtbf
        
        mtbf = 1.0_dp / lambda
    end function exponential_mtbf
    
    ! Calculate MTTF using Erlang distribution
    function erlang_mttf(k, lambda) result(mttf)
        integer, intent(in) :: k
        real(dp), intent(in) :: lambda
        real(dp) :: mttf
        
        mttf = real(k, dp) / lambda
    end function erlang_mttf
    
    ! Exponential reliability function R(t) = exp(-lambda*t)
    function exponential_reliability(lambda, t) result(reliability)
        real(dp), intent(in) :: lambda, t
        real(dp) :: reliability
        
        reliability = exp(-lambda * t)
    end function exponential_reliability
    
    ! Erlang reliability using incomplete gamma function approximation
    function erlang_reliability(k, lambda, t) result(reliability)
        integer, intent(in) :: k
        real(dp), intent(in) :: lambda, t
        real(dp) :: reliability
        real(dp) :: cdf_value, term
        integer :: i
        
        ! Calculate CDF = 1 - sum_{i=0}^{k-1} [exp(-lambda*t) * (lambda*t)^i / i!]
        cdf_value = 0.0_dp
        term = exp(-lambda * t)
        
        do i = 0, k - 1
            if (i > 0) then
                term = term * (lambda * t) / real(i, dp)
            end if
            cdf_value = cdf_value + term
        end do
        
        reliability = 1.0_dp - cdf_value
    end function erlang_reliability
    
    ! Calculate MTBF for array of sensors
    subroutine calculate_mtbf_array(n, rates, mtbf_arr)
        integer, intent(in) :: n
        real(dp), dimension(:), intent(in) :: rates
        real(dp), dimension(:), intent(out) :: mtbf_arr
        integer :: i
        
        do i = 1, n
            mtbf_arr(i) = exponential_mtbf(rates(i))
        end do
    end subroutine calculate_mtbf_array
    
    ! Calculate MTTF for array of sensors
    subroutine calculate_mttf_array(n, k_vals, rates, mttf_arr)
        integer, intent(in) :: n
        integer, dimension(:), intent(in) :: k_vals
        real(dp), dimension(:), intent(in) :: rates
        real(dp), dimension(:), intent(out) :: mttf_arr
        integer :: i
        
        do i = 1, n
            mttf_arr(i) = erlang_mttf(k_vals(i), rates(i))
        end do
    end subroutine calculate_mttf_array
    
    ! Calculate fleet-wide reliability
    subroutine calculate_fleet_reliability(n, k_vals, rates, t_horizon, fleet_rel)
        integer, intent(in) :: n
        integer, dimension(:), intent(in) :: k_vals
        real(dp), dimension(:), intent(in) :: rates
        real(dp), intent(in) :: t_horizon
        real(dp), intent(out) :: fleet_rel
        real(dp) :: rel_sum
        integer :: i
        
        rel_sum = 0.0_dp
        
        do i = 1, n
            rel_sum = rel_sum + erlang_reliability(k_vals(i), rates(i), t_horizon)
        end do
        
        fleet_rel = rel_sum / real(n, dp)
    end subroutine calculate_fleet_reliability
    
    ! Classify sensors by health status
    subroutine classify_sensors_by_health(n, health, active, warning, failed)
        integer, intent(in) :: n
        real(dp), dimension(:), intent(in) :: health
        integer, intent(out) :: active, warning, failed
        integer :: i
        
        active = 0
        warning = 0
        failed = 0
        
        do i = 1, n
            if (health(i) > 70.0_dp) then
                active = active + 1
            else if (health(i) > 30.0_dp) then
                warning = warning + 1
            else
                failed = failed + 1
            end if
        end do
    end subroutine classify_sensors_by_health
    
    ! Analyze maintenance queue using M/M/c model
    subroutine analyze_maintenance_queue(arr_rate, serv_rate, n_servers, &
                                          util, avg_queue, avg_wait)
        real(dp), intent(in) :: arr_rate, serv_rate
        integer, intent(in) :: n_servers
        real(dp), intent(out) :: util, avg_queue, avg_wait
        real(dp) :: rho, lambda_mu, p0, sum_term, last_term
        integer :: i
        
        rho = arr_rate / (real(n_servers, dp) * serv_rate)
        util = rho
        
        if (rho >= 1.0_dp) then
            avg_queue = -1.0_dp
            avg_wait = -1.0_dp
            return
        end if
        
        lambda_mu = arr_rate / serv_rate
        
        ! Calculate P0
        sum_term = 0.0_dp
        do i = 0, n_servers - 1
            sum_term = sum_term + (lambda_mu ** i) / factorial(i)
        end do
        
        last_term = (lambda_mu ** n_servers) / (factorial(n_servers) * (1.0_dp - rho))
        p0 = 1.0_dp / (sum_term + last_term)
        
        ! Calculate Lq
        avg_queue = (p0 * (lambda_mu ** n_servers) * rho) / &
                    (factorial(n_servers) * ((1.0_dp - rho) ** 2))
        
        ! Calculate Wq
        if (arr_rate > 0.0_dp) then
            avg_wait = avg_queue / arr_rate
        else
            avg_wait = 0.0_dp
        end if
    end subroutine analyze_maintenance_queue
    
    ! Factorial function
    function factorial(n) result(fact)
        integer, intent(in) :: n
        real(dp) :: fact
        integer :: i
        
        fact = 1.0_dp
        do i = 2, n
            fact = fact * real(i, dp)
        end do
    end function factorial
    
    ! Cascade failure risk analysis
    subroutine analyze_cascade_risk(n_failed, n_total)
        integer, intent(in) :: n_failed, n_total
        real(dp) :: risk_factor, dep_mult
        integer :: expected_additional
        character(len=6) :: risk_level
        
        risk_factor = real(n_failed, dp) / real(n_total, dp)
        
        if (risk_factor > 0.2_dp) then
            dep_mult = 1.5_dp
        else if (risk_factor > 0.1_dp) then
            dep_mult = 1.2_dp
        else
            dep_mult = 1.0_dp
        end if
        
        expected_additional = int(real(n_failed, dp) * dep_mult * 0.3_dp)
        
        if (risk_factor > 0.15_dp) then
            risk_level = 'HIGH'
        else if (risk_factor > 0.08_dp) then
            risk_level = 'MEDIUM'
        else
            risk_level = 'LOW'
        end if
        
        print *, '=== Cascade Failure Risk Analysis ==='
        print '(A,I4)', ' Current Failures: ', n_failed
        print '(A,F8.5)', ' Cascade Risk Factor: ', risk_factor
        print '(A,I4)', ' Expected Additional Failures: ', expected_additional
        print '(A,A)', ' Risk Level: ', trim(risk_level)
        print *, ''
    end subroutine analyze_cascade_risk
    
end program iot_reliability_tracker

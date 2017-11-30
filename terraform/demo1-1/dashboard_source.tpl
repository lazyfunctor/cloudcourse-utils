{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${asg_name}", { "period": 60 } ],
                    [ "AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "${alb_tg}", "LoadBalancer", "${alb}", { "period": 60, "stat": "Maximum" } ],
                    [ ".", "UnHealthyHostCount", ".", ".", ".", ".", { "period": 60, "stat": "Maximum" } ]
                ],
                "region": "${region}",
                "period": 60,
                "title": "CPU & Healthy Instances"
            }
        },
        {
            "type": "metric",
            "x": 6,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${alb}", { "stat": "Sum", "period": 60 } ],
                    [ ".", "HTTPCode_Target_4XX_Count", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "HTTPCode_ELB_4XX_Count", ".", ".", { "stat": "Sum", "period": 60 } ],
                    [ ".", "RequestCount", ".", ".", { "period": 60, "stat": "Sum" } ],
                    [ ".", "RequestCountPerTarget", "TargetGroup", "${alb_tg}", { "period": 60, "stat": "Sum" } ]
                ],
                "region": "${region}",
                "period": 60,
                "title": "Request Count"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb}", { "period": 60, "stat": "p99" } ],
                    [ "...", { "period": 60, "stat": "p95" } ],
                    [ "...", { "period": 60, "stat": "p90" } ],
                    [ "...", { "period": 60, "stat": "Average" } ]
                ],
                "region": "${region}",
                "period": 60,
                "title": "Latencies"
            }
        }
    ]
}
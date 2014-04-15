#libraries
AWS = require("aws-sdk")
moment = require("moment")
mongoose = require("mongoose")
Schema = mongoose.Schema
mongoose.connect "mongodb://localhost/data"

##config
AWS.config.loadFromPath "./config.json"

database = mongoose.model("Data",
  Enviroment : String
  EC2Instances: Number
  CPU: String
  BW: String
  Latency: String
  RequestCount: Number
  Timestamp: Date
)


check = () ->
  EndTime = moment().subtract "minutes", 1
  StartTime = moment().subtract "minutes", 2
  elasticdata = {EnvironmentName: "#{process.env.ENVIROMENT}"}

  elasticbeanstalk = new AWS.ElasticBeanstalk()
  cloudwatch = new AWS.CloudWatch()

  elasticbeanstalk.describeEnvironmentResources elasticdata, (err, data) ->
    if err
      console.log err, err.stack
    else
      test =
        Dimensions: [{Name: 'LoadBalancerName', Value: 'awseb-e-p-AWSEBLoa-GLS2X7QKPHXM'}]
        Namespace: "AWS/ELB"

      params =
        EndTime: EndTime.toISOString()
        Period: '60'
        StartTime: StartTime.toISOString()

      params_ec2 =
        Dimensions: []
        Namespace: "AWS/EC2"

      params_elb =
        Dimensions: []
        Namespace: "AWS/ELB"

      CPUUtilization =
        MetricName: "CPUUtilization"
        Statistics: ['Average']
        Dimensions: params_ec2.Dimensions
        Namespace: params_ec2.Namespace
        EndTime: params.EndTime
        Period: params.Period
        StartTime: params.StartTime

      NetworkOut =
        MetricName: "NetworkOut"
        Statistics: ['Maximum']
        Dimensions: params_ec2.Dimensions
        Namespace: params_ec2.Namespace
        EndTime: params.EndTime
        Period: params.Period
        StartTime: params.StartTime

      Latency =
        Dimensions: params_elb.Dimensions
        Namespace: params_elb.Namespace
        MetricName: "Latency"
        Statistics: ['Average']
        EndTime: params.EndTime
        Period: params.Period
        StartTime: params.StartTime

      RequestCount =
        Dimensions: params_elb.Dimensions
        Namespace: params_elb.Namespace
        MetricName: "RequestCount"
        Statistics: ['Sum']
        EndTime: params.EndTime
        Period: params.Period
        StartTime: params.StartTime

      instances = data.EnvironmentResources.Instances
      for instance in instances
        params_ec2.Dimensions.push { Name: 'InstanceId', Value: instance.Id }

      balancers = data.EnvironmentResources.LoadBalancers
      for balancer in balancers
        params_elb.Dimensions.push { Name: 'LoadBalancerName', Value: balancer.Name }

      result =
        Enviroment: "#{process.env.ENVIROMENT}"
        EC2Instances: instances.length
        CPU: ''
        BW: ''
        Latency: ''
        RequestCount: ''
        Timestamp: ''

      cloudwatch.getMetricStatistics CPUUtilization, (err, data) ->
        if err
          console.log err, err.stack
        else
          result.CPU = data.Datapoints[0].Average
          cloudwatch.getMetricStatistics NetworkOut, (err, data) ->
            if err
              console.log err, err.stack
            else
              result.BW = data.Datapoints[0].Maximum
              cloudwatch.getMetricStatistics Latency, (err, data) ->
                if err
                  console.log err, err.stack
                else
                  result.Latency = data.Datapoints[0].Average
                  cloudwatch.getMetricStatistics RequestCount, (err, data) ->
                    if err
                      console.log err, err.stack
                    else
                      result.RequestCount = data.Datapoints[0].Sum
                      result.Timestamp = data.Datapoints[0].Timestamp
                      console.log result
                      saveData = new database(result)
                      saveData.save (err) ->
                        console.log "fuuuuuu"  if err
                        return
                      setTimeout check, 60000

check()

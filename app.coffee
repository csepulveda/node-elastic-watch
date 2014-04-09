#libraries
AWS = require("aws-sdk")
moment = require("moment")

##config
AWS.config.loadFromPath "./config.json"
elasticbeanstalk = new AWS.ElasticBeanstalk()
cloudwatch = new AWS.CloudWatch()


##Varibles
EndTime = moment().subtract "minutes", 1
StartTime = moment().subtract "minutes", 2
elasticdata = {EnvironmentName: 'estadiocdf-qa'}


elasticbeanstalk.describeEnvironmentResources elasticdata, (err, data) ->
  if err
    console.log err, err.stack
  else

    params =
      Dimensions: []
      Namespace: "AWS/EC2"
      EndTime: EndTime.toISOString()
      Period: '60'
      StartTime: StartTime.toISOString()

    cpu =
      MetricName: "CPUUtilization"
      Statistics: ['Average']
      Dimensions: params.Dimensions
      Namespace: params.Namespace
      EndTime: params.EndTime
      Period: params.Period
      StartTime: params.StartTime

    bw =
      MetricName: "NetworkOut"
      Statistics: ['Maximum']
      Dimensions: params.Dimensions
      Namespace: params.Namespace
      EndTime: params.EndTime
      Period: params.Period
      StartTime: params.StartTime


    element = data.EnvironmentResources.Instances
    for instance in element
      params.Dimensions.push { Name: 'InstanceId', Value: instance.Id }

    result =
      CPU: ''
      BW: ''
      Timestamp: ''

    cloudwatch.getMetricStatistics cpu, (err, data) ->
      if err
        console.log err, err.stack
      else
        result.CPU = data.Datapoints[0].Average
        cloudwatch.getMetricStatistics bw, (err, data) ->
          if err
            console.log err, err.stack
          else
            result.BW = data.Datapoints[0].Maximum
            result.Timestamp = data.Datapoints[0].Timestamp
            console.log result
          return
      return
  return

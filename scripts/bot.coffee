# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md


module.exports = (robot) ->

  CSON = require('cson')
  config = CSON.parseFile('configs.cson')
  secrets = CSON.parseFile('secrets.cson')
  # console.log(config)


  robotInit = config['AI Robot'].init
  robotParams = config['AI Robot'].params
  agent = config['AI Robot'].agent
  user = config['AI Robot'].user
  robotContext = ''
  clearOnEachResponse = false
  example = config['AI Robot'].example

  robot.hear /(.*)/i, (res) ->    
    if res.message.text == 'show knowledge' || res.message.text == 'sk'     
      res.send robotInit + robotContext
      return

    if res.message.text == 'modes' 
      counter = 1
      for mode in config.modes
        res.send counter++ + ". " + mode
      return            

    counter = 0
    for mode in config.modes
      counter++
      if res.message.text == mode || res.message.text.startsWith("mode " + counter)
        robotInit = config[mode].init
        robotParams = config[mode].params
        agent = config[mode].agent
        user = config[mode].user
        example = config[mode].example
        clearOnEachResponse = config[mode].clearOnEachResponse
        robotContext = ''
        res.send mode + ":\n" + robotInit
        return
    
    if robotContext.length > 2000 
        robotContext = robotContext.substr(robotContext.length - 2000)
        robotContext = robotContext.substr(robotContext.indexOf(agent))

    if clearOnEachResponse
      robotContext = ""
    else if res.message.text == '.'     
      robotContext = robotContext + user + '\n' + agent
    else if res.message.text == 'example' || res.message.text == 'ex'
      res.send user + example + '\n' + agent
      robotContext = robotContext + user + example + '\n' + agent
    else
      robotContext = robotContext + user + res.message.text + '\n' + agent

    robotParams["prompt"] = robotInit + robotContext;
    data = JSON.stringify(robotParams)
    #res.send "#{data}"
    res.http("https://api.openai.com/v1/engines/davinci/completions")
      .header('Content-Type', 'application/json')
      .auth('bearer', secrets.authKey)
      .post(data) (err, response, body) ->
        if err
          res.send "Encountered an error :( #{err}"
          return
        else
          jsonResponse = JSON.parse body
          robotContext += jsonResponse.choices[0].text + '\n'
          res.reply jsonResponse.choices[0].text
          #res.reply body
   
  enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  
  robot.enter (res) ->
    res.send res.random enterReplies
  robot.leave (res) ->
    res.send res.random leaveReplies
    
  robot.error (err, res) ->
    robot.logger.error "DOES NOT COMPUTE"
    if res?
      res.reply "DOES NOT COMPUTE"
  
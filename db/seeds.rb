# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
def flush_database()
  $redis.flushall
end

def createIndices()
  $redis.call(['FT.CREATE', 'idx:users', 'ON', 'HASH', 'PREFIX', '1', 'user', 'SCHEMA', 'firstname', 'TEXT', 'lastname', 'TEXT', 'city', 'TAG', 'SORTABLE', 'country', 'TAG', 'SORTABLE', 'username', 'TAG', 'SORTABLE'])
  $redis.call(['FT.CREATE', 'idx:messages', 'ON', 'HASH', 'PREFIX', '1', 'message', 'SCHEMA', 'username', 'TAG', 'SORTABLE', 'channel', 'TAG', 'SORTABLE', 'message', 'TEXT'])
end

def loadUserProfiles()
  users = JSON.parse(File.read('./db/sample_data/users.json'))

  users.each do |user|
    puts("Loading user #{user['username']}.")

    $redis.hset("user:#{user['username']}", user)
    $redis.sadd('usernames', user['username'])
  end
end

def verifyUserProfiles()
  numUsers = $redis.scard('usernames')
  ada = $redis.hgetall("user:ada")

  if (numUsers == 6) && (ada['firstname'] == 'Ada') && (ada['country'] == 'England')
    puts('User verification OK.')
  else
    puts('User verification failed:')
  end
end


def loadMessages()
  messages = JSON.parse(File.read('./db/sample_data/messages.json'))

  messages.each do |message|
    puts("Posting message by #{message['username']} to channel #{message['channel']}.")

    $redis.sadd('channels', message['channel'])
    $redis.xadd("channel:#{message['channel']}", {'type': 'message'}, id: message['id'])
    $redis.hset("message:#{message['id']}", {
      username: message['username'],
      channel: message['channel'],
      message: message['message']
    })
  end
end


def verifyMessages()
  cricketCount = $redis.xlen('channel:cricket')
  channelNames = $redis.smembers('channels')
  cricketMessageId = $redis.xrange('channel:cricket', '-', '+', count: '1')
  techMessage = $redis.hgetall('message:1631623314829-0')

  if (cricketCount == 3) && channelNames.include?('cricket') && channelNames.include?('tech') && channelNames.include?('random') && channelNames.include?('tennis') && cricketMessageId[0][0] == '1631623305083-0' && techMessage['channel'] == 'tech' && (techMessage['username'] == 'ada')
    puts('Message verification successful.')
  else
    puts('Message verification failed:')
  end
end

def verifySearch()
  userSearchResults = $redis.call('FT.SEARCH', 'idx:users', '@firstname:Simon @city:{Nottingham}', 'LIMIT', '0', '999999')
  messageSearchResults = $redis.call('FT.SEARCH', 'idx:messages', '@channel:{cricket|tech} @username:{wasim}', 'LIMIT', '0', '999999')

  if userSearchResults[0] == 1 &&
    userSearchResults[2][3] == 'Prickett' &&
    messageSearchResults[0] == 2 &&
    messageSearchResults[2][1] == 'wasim' &&
    messageSearchResults[2][3] == 'tech'
    puts('Search verification successful.')
  else
    puts('Search verification failed:')
  end
end


def loadAndVerifyData()
  flush_database()
  createIndices()
  loadUserProfiles()
  verifyUserProfiles()
  loadMessages()
  verifyMessages()
  verifySearch()
end

loadAndVerifyData()

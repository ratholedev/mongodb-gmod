# MongoDB GMod
Simple MongoDB Wrapper for Garry's Mod

## Information
### How to install
You can put this on path "lua/autorun/server" or as gamemode serverside module or as kind of addon serverside module.

### Usage
In the file itself, each method has a little memo about what each parameter is and what kind of method it is (although the name of the method speaks for itself)

### Requires
This library requires [GMSV MongoDB](https://github.com/ProrabVolodya/gmsv_mongodb) module.

## Example
```lua
-- Initialize connection with DB server
MongoLib.connect('mongodb://localhost:27017/', 'mongolib-db')

-- Callback hook
hook.Add('MongoDBInitialized', 'MongoDBServer_Initialize', function()
	print 'Successfully connected to MongoDB server'
end)

-- Getting database information
local getDb = MongoLib.getDb()

-- Or change our database to another
MongoLib.changeDb('another-db')

if not MongoLib.collections('the_collection'):Exist() then
	MongoLib.collections('the_collection'):Add()
end

-- Inserting something to collection
MongoLib.query('the_collection')
	:Insert('player'):Set(ply:Name())
	:Insert('health'):Set(ply:Health())
	:Insert('money'):Set(ply:GetMoney())
	-- etc.
:Run()

-- Select query for find record with any identifier
local getPlayer = MongoLib.query('the_collection'):Find():Criteria({player = 'John'}):Run()

-- Updating player info
MongoLib.query('the_collection')
	:Update('money'):Set(getPlayer[1].money - 500)
:Criteria({player = getPlayer[1].player}):Run()
```

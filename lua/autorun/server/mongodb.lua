local file_exists = file.Exists('bin/gmsv_mongodb_'..(system.IsLinux() and 'linux' or system.IsOSX() and 'osx' or 'win32')..'.dll', 'LUA')

require 'mongodb'

MongoLib = MongoLib or {}
MongoQuery = {}
MongoQuery.__index = MongoQuery

local client
local connectedToMongoDB = false
local database

--[[
	MongoLib.connect
	params:
		@string | connection_uri | A connection URI to your MongoDB server
		@string | dbName | Database name for connection
	callback:
		@hook | MongoDBInitialized | Callback hook if client successfully connected
--]]
function MongoLib.connect(connection_uri, dbName)
	if not file_exists then
		error 'MongoDB module file not found. Try install: https://github.com/dhkatz/gmsv_mongodb'
		return
	end
	if not dbName or dbName:len() <= 0 then
		error 'Parameter "Database name" is not defined'
		return
	end

	client = client or mongodb.Client(connection_uri, 'GMod Lua MongoLib')

	local testConnection = client:DatabaseList()

	if type(testConnection) == 'table' and #testConnection >= 1 then
		connectedToMongoDB = true

		database = client:Database(dbName)

		hook.Call('MongoDBInitialized', nil)
	end
end

--[[
	MongoLib.isConnected
	return:
		@boolean | Returns successfully connected or not?
--]]
function MongoLib.isConnected()
	return connectedToMongoDB
end

--[[
	MongoLib.getClient
	return:
		@userdata | Returns MongoDB client userdata
--]]
function MongoLib.getClient()
	return client
end

--[[
	MongoLib.getDb
	return:
		@userdata | Returns MongoDB database userdata
--]]
function MongoLib.getDb()
	return database
end


--[[
	MongoLib.changeDb
	params:
		@string | dbName | Required database name
--]]
function MongoLib.changeDb(dbName)
	if not connectedToMongoDB then error 'No connection to MongoDB server!' return nil end
	if not dbName or type(dbName) ~= 'string' then error 'Invalid database name!' return nil end

	if string.len(client:Database(dbName):Name()) >= 1 then
		database = client:Database(dbName)
	end
end

--[[
	MongoLib.collections
	params:
		@string | collectionName | Name of collection (ar as called table) for take information

	return:
		@object | Returns obj or nil value
--]]
function MongoLib.collections(collectionName)
	if not connectedToMongoDB then error 'No connection to MongoDB server!' return nil end
	if not collectionName or type(collectionName) ~= 'string' or collectionName:len() <= 0 then error 'Invalid collection name!' return nil end
	if not database then error 'Database is not defined!' return end

	local obj = setmetatable({}, MongoQuery)
	obj.withCollections = true
	obj.collectionName = collectionName

	return obj
end

--[[
	Object:Add
	Add to database collection
	return:
		@boolean | Returns existing collection after create
--]]
function MongoQuery:Add()
	if not self.withCollections then return nil end

	database:Command({create = self.collectionName})
	return database:HasCollection(self.collectionName)
end

--[[
	Object:Exist
	Checks exsit collection or not
	return:
		@boolean | Returns existing collection or not
--]]
function MongoQuery:Exist()
	if not self.withCollections then return nil end

	return database:HasCollection(self.collectionName)
end

--[[
	Object:Get
	Gets collection infomation
	return:
		@UserData | Returns data of collection
--]]
function MongoQuery:Get()
	if not self.withCollections then return nil end

	return database:GetCollection(self.collectionName)
end

--[[
	Object:Drop
	Remove selected collection from database
--]]
function MongoQuery:Drop()
	if not self.withCollections then return nil end

	if database:HasCollection(self.collectionName) then
		database:GetCollection(self.collectionName):__gc()
		database:Command({drop = self.collectionName})
	end
end

--[[
	MongoLib.query
	params:
		@string | collectionName | Name of collection (ar as called table) for take information
	return:
		@object | Returns obj or nil value
--]]
function MongoLib.query(collectionName)
	if not connectedToMongoDB then error 'No connection to MongoDB server!' return nil end
	if not collectionName or type(collectionName) ~= 'string' or collectionName:len() <= 0 then error 'Invalid collection name!' return nil end

	local obj = setmetatable({}, MongoQuery)
	obj.queryRecords = true
	obj.collectionName = collectionName
	obj.criteriaTable = {}
	obj.values = {}
	obj.selectQuery = {false}
	obj.insertQuery = {false, {}}
	obj.updateQuery = {false, false, {}, {}}
	obj.deleteQuery = {false}

	return obj
end

--[[
	Object:Find
	Find records in collection
	return:
		@object | Return themself
--]]
function MongoQuery:Find()
	if not self.queryRecords then return nil end
	if self.selectQuery[1] ~= true then self.selectQuery[1] = not self.selectQuery[1] end

	return self
end

--[[
	Object:Insert
	Insert field
	params:
		@string | fieldName | the field in which you want to insert something
	return:
		@boolean | Return themself
--]]
function MongoQuery:Insert(fieldName)
	if not self.queryRecords then return nil end
	if self.insertQuery[1] ~= true then self.insertQuery[1] = not self.insertQuery[1] end

	table.insert(self.insertQuery[2], fieldName or '')
	return self
end

--[[
	Object:Update
	Update field
	params:
		@string | fieldName | the field that needs to be changed
	return:
		@boolean | Return themself
--]]
function MongoQuery:Update(fieldName)
	if not self.queryRecords then return nil end
	if self.updateQuery[1] ~= true then self.updateQuery[1] = not self.updateQuery[1] end

	table.insert(self.updateQuery[3], fieldName or '')
	return self
end

--[[
	Object:Rename
	Change old fieldname to new
	params:
		@string | newFieldname | new name of field, if it is required
	return:
		@boolean | Return themself
--]]
function MongoQuery:Rename(newFieldName)
	if not self.queryRecords then return nil end
	if #self.updateQuery[3] <= 0 then return nil end
	if self.updateQuery[2] ~= true then self.updateQuery[2] = not self.updateQuery[2] end

	table.insert(self.updateQuery[4], newFieldName or '')
	return self
end

--[[
	Object:Set
	Set up value of field (Using with :Update() and :Insert())
	params:
		@any | value | value, just a value
	return:
		@object | Return themself
--]]
function MongoQuery:Set(value)
	if not self.queryRecords then return nil end
	-- if #self.insertQuery[2] <= 0 or #self.updateQuery[3] <= 0 then return nil end
	
	table.insert(self.values, value)
	return self
end

--[[
	Object:Criteria
	Used to highlight a specific record on database
	params:
		@table | criteria | Set up criteria of one or many field
	return:
		@object | Return themself
--]]
function MongoQuery:Criteria(criteria)
	if not self.queryRecords then return nil end

	self.criteriaTable = istable(criteria) and criteria or {}
	return self
end

--[[
	Object:Delete
	Delete record from collection
	return:
		@object | Return themself
--]]
function MongoQuery:Delete()
	if not self.queryRecords then return nil end
	if self.deleteQuery[1] ~= true then self.deleteQuery[1] = not self.deleteQuery[1] end

	return self
end

--[[
	Object:Run
	Launches your whole mess you wrote
	return:
		@table | Return result of query
--]]
function MongoQuery:Run()
	if not connectedToMongoDB then error 'No connection to MongoDB server!' return nil end
	if not self.queryRecords then return nil end
	if not self.collectionName or type(self.collectionName) ~= 'string' or self.collectionName:len() <= 0 then error 'Invalid collection name!' return nil end
	if not database then error 'Database is not defined!' return nil end
	if not database:HasCollection(self.collectionName) then error 'Collection not found on database!' return nil end

	local tempTable = {}

	if self.selectQuery[1] == true then
		return database:GetCollection(self.collectionName):Find(self.criteriaTable or {})
	elseif self.insertQuery[1] == true then
		for i = 1, table.Count(self.insertQuery[2]) do
			tempTable[self.insertQuery[2][i]] = self.values[i]
		end

		database:GetCollection(self.collectionName):Insert(tempTable)

		return {}
	elseif self.updateQuery[1] == true then
		if self.updateQuery[2] == true then
			tempTable = {['$rename'] = {}}

			for i = 1, table.Count(self.updateQuery[3]) do
				tempTable['$rename'][self.updateQuery[3][i]] = self.updateQuery[4][i]
			end
		else
			tempTable = {['$set'] = {}}

			for i = 1, table.Count(self.updateQuery[3]) do
				tempTable['$set'][self.updateQuery[3][i]] = self.values[i]
			end 
		end

		database:GetCollection(self.collectionName):Update(self.criteriaTable or {}, tempTable)

		return {}
	elseif self.deleteQuery[1] == true then
		database:GetCollection(self.collectionName):Remove(self.criteriaTable or {})

		return {}
	end
end

-- I know there is no Bulk() method. There will be one, but later
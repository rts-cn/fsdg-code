-- 这里我们使用SQLite数据库，先初始化一个DB Handle
local dbh = freeswitch.Dbh("/tmp/test.db")

-- 如果使用ODBC数据库，可以使用以下格式
-- local dbh = freeswitch.Dbh("odbc://dsn username password")

assert(dbh:connected()) -- 断言，测试数据库是否成功连接，如果连接不成功则退出


-- test_reactive测试数据库表是否存在，它有三个参数：
-- 测试语句（查询，SELECT），删除语句（DROP）及创建语句（CREATE）
-- 意思是说，如果SELECT不成功，则先试图运行一个DROP操作，再用CREATE重新创建
dbh:test_reactive("SELECT * FROM test_table",
				  "DROP TABLE test_table",
				  "CREATE TABLE test_table (id INTEGER, name VARCHAR(255))")

-- 往我们新建的表中插入两条数据
dbh:query("INSERT INTO test_table VALUES(1, 'foo')")
dbh:query("INSERT INTO test_table VALUES(2, 'bar')")

-- 查询数据，并对查询结果集的每一行回调一个匿名函数（function），
-- 查询结果集将作为一个Table传入row参数，则实际列的值可以用row.id、row.name引用
dbh:query("SELECT id, name FROM test_table", function(row)
	freeswitch.consoleLog("INFO", string.format("Row #%s: %s\n", row.id, row.name))
end)

-- 更新表
dbh:query("UPDATE test_table SET name = 'changed'")

-- 打印更新行数（Affected Rows）
freeswitch.consoleLog("INFO", "Affected rows: " .. dbh:affected_rows() .. "\n")

-- 查看更新后的结果
dbh:query("SELECT id, name FROM test_table", function(row)
	freeswitch.consoleLog("INFO", string.format("Row #%s: %s\n", row.id, row.name))
end)

-- 释放Handle，可选，默认用完后会自动释放
dbh:release()

-- 应答
session:answer()

-- 睡一小会（毫秒）
session:sleep(1000)

-- 播放声音文件
session:streamFile("/tmp/hello-lua.wav")

-- 挂机
session:hangup()

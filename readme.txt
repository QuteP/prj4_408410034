如何編譯：

1. 將prj4_408410034.tar.bz2內的檔案解壓縮後與antlr官網下載下來的antlr-3.5.2-complete.jar放在同一資料夾裡
2. 在此資料夾執行「make」指令

如何執行：

在此資料夾裡執行如下指令。

測試程式1：
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test test1.c > test1.ll
	
	llc test1.ll
	
	gcc -o test1 -no-pie -Iincludes test1.s
	
	./test1

測試程式2：
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test test2.c > test2.ll
	
	llc test2.ll
	
	gcc -o test2 -no-pie -Iincludes test2.s
	
	./test2

測試程式3：
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test test3.c > test3.ll
	
	llc test3.ll
	
	gcc -o test3 -no-pie -Iincludes test3.s
	
	./test3

之後結果就會印在終端機裡。




JFLAGS = -cp
AR = antlr-3.5.2-complete.jar
TL = org.antlr.Tool
JA = java
JC = javac
.SUFFIXES: .java .class
.java.class:
	$(JA) $(JFLAGS) $(AR) $(TL) myCompiler.g
	$(JC) $(JFLAGS) $(AR):. myCompiler_test.java 

# This uses the line continuation character (\) for readability
# You can list these all on a single line, separated by a space instead.
# If your version of make can't handle the leading tabs on each
# line, just remove them (these are also just added for readability).
CLASSES = \
	myCompiler_test.java \
	myCompilerLexer.java \
	myCompilerParser.java \
	
default: classes

classes: $(CLASSES:.java=.class)

clean:
	$(RM) *.class

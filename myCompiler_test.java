import org.antlr.runtime.*;
import org.antlr.runtime.tree.*;

public class myCompiler_test {
	public static void main(String[] args) throws Exception {

      CharStream input = new ANTLRFileStream(args[0]);
      myCompilerLexer lexer = new myCompilerLexer(input);
      CommonTokenStream tokens = new CommonTokenStream(lexer);
 
      myCompilerParser parser = new myCompilerParser(tokens);
      parser.program();

	}
}

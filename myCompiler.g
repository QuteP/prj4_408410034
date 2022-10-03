grammar myCompiler;

options {
   language = Java;
}

@header {
    import java.util.HashMap;
    import java.util.Scanner;
	import java.util.ArrayList;
}

@members {

	HashMap<Integer, String> ifpMap= new HashMap<Integer, String>();//(cnt, position or delta)
	HashMap<Integer, Info> ifcMap= new HashMap<Integer, Info>();//(cnt, comparison_statement)
	ArrayList<Integer> conArr=new ArrayList<Integer>();
	ArrayList<Integer> staArr=new ArrayList<Integer>();
	int elsevalue=-1;
	int ifcnt=0;
    int iocnt=1;
    int ifvalue=0;
    int arrvalue=0;
	int assvalue=0;
	int printValue=0;
	int scanfValue=0;
	String printStr="";
	String printPara="";
        // Type information.
    public enum Type{
       ERR, BOOL, VOID, INT, FLOAT, DOUBLE, LONG, CHAR, CONST_INT, CONST_FLOAT;
    }

    // This structure is used to record the information of a variable or a constant.
    class tVar {
	   int   varIndex; // temporary variable's index. Ex: t1, t2, ..., etc.
	   int   iValue;   // value of constant integer. Ex: 123.
	   double fValue;   // value of constant floating point. Ex: 2.314.
	   int	arrSize;
	   String varID;
	};

    class Info {
       Type theType;  // type information.
       tVar theVar;
	   
	   Info() {
          theType = Type.ERR;
		  theVar = new tVar();
	   }
    };

	
    // ============================================
    // Create a symbol table.
	// ArrayList is easy to extend to add more info. into symbol table.
	//
	// The structure of symbol table:
	// <variable ID, [Type, [varIndex or iValue, or fValue]]>
	//    - type: the variable type   (please check "enum Type")
	//    - varIndex: the variable's index, ex: t1, t2, ...
	//    - iValue: value of integer constant.
	//    - fValue: value of floating-point constant.
    // ============================================

    HashMap<String, Info> symtab = new HashMap<String, Info>();

    // labelCount is used to represent temporary label.
    // The first index is 0.
    int labelCount = 0;
	
    // varCount is used to represent temporary variables.
    // The first index is 0.
    int varCount = 0;
	int strCount = 0;

    // Record all assembly instructions.
    List<String> TextCode = new ArrayList<String>();


    /*
     * Output prologue.
     */
    void prologue()
    {
	   TextCode.add("define dso_local i32 @main()");
	   TextCode.add("{");
    }
    
	
    /*
     * Output epilogue.
     */
    void epilogue()
    {
       /* handle epilogue */
	   
    }
    
    
    /* Generate a new label */
    String newLabel()
    {
       labelCount ++;
       return (new String("L")) + Integer.toString(labelCount);
    } 
    
    
    public List<String> getTextCode()
    {
       return TextCode;
    }
}


program:(INCLUDE '<' STRING '>')*  type MAIN {
           /* Output function prologue */
		    if($type.attr_type == Type.INT){
				TextCode.add("define dso_local i32 @main()");
			}
			else if($type.attr_type == Type.VOID){
				TextCode.add("define dso_local void @main()");
			}
	   		TextCode.add("{");
        } '(' (ARGC ',' ARGV)? ')' '{' statements '}' {
			if( !(TextCode.get(TextCode.size()-1).contains("ret"))){
				if($type.attr_type == Type.INT){
					TextCode.add("ret i32 0");
				}
				else if($type.attr_type == Type.VOID){
					TextCode.add("ret void");
				}
			}
       		TextCode.add("}");
       		for (String i : TextCode) {
			    System.out.println(i);
			}
		};

//rememeber to mod all the "replace"
//float things may lead to some error

declarations:
			type {arrvalue=0;Info the_entry = new Info();} a_1=ID ('[' a=Integer_constant ']' {arrvalue=1;assvalue=0;})? ('=' b=arith_expression {assvalue=1;})? ';' 
           {
			the_entry.theType = $type.attr_type;
			the_entry.theVar.varIndex = varCount;
			the_entry.theVar.varID=$a_1.text;
			varCount++;
			

			if (arrvalue==0) { 
				if ($type.attr_type == Type.INT) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
				}
				else if($type.attr_type == Type.DOUBLE) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca double, align 8");
				}
				else if($type.attr_type == Type.FLOAT) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca float, align 4");
				}
				else if($type.attr_type == Type.LONG) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca i64, align 8");
				}
			}
			else if(arrvalue==1){ 
				if ($type.attr_type == Type.INT) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca [" + Integer.parseInt($a.text) +  " x i32], align 16");
				}
				else if($type.attr_type == Type.DOUBLE) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca [" + Integer.parseInt($a.text) +  " x double], align 16");
				}
				else if($type.attr_type == Type.FLOAT) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca [" + Integer.parseInt($a.text) +  " x float], align 16");
				}
				else if($type.attr_type == Type.LONG) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca [" + Integer.parseInt($a.text) +  " x i64], align 16");
				}
				the_entry.theVar.arrSize=Integer.parseInt($a.text);
			}
			symtab.put($a_1.text, the_entry);
			if(assvalue==1) { 
				if (arrvalue==0) { 
					if ($type.attr_type == Type.INT) { 
						if($b.theInfo.theType == Type.INT)
						{
							TextCode.add("store i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType == Type.CONST_INT)
						{
							TextCode.add("store i32 " + $b.theInfo.theVar.iValue + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType==Type.LONG)
						{	
							TextCode.add("\%" + "t" + varCount + " = trunc i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i32");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType==Type.FLOAT)
						{

							TextCode.add("\%" + "t" + varCount + " = fptosi float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i32");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType==Type.DOUBLE)
						{
							TextCode.add("\%" + "t" + varCount + " = fptosi double " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i32");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType==Type.CONST_FLOAT)
						{
							double tempd=$b.theInfo.theVar.fValue;
							TextCode.add("store i32 " + (int)tempd + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}				
					}
					else if($type.attr_type == Type.DOUBLE) { 
						if($b.theInfo.theType == Type.INT)
						{
							TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store double " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType == Type.CONST_INT)
						{
							String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
							TextCode.add("store double " + tempf + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType==Type.LONG)
						{	
							TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store double " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType==Type.FLOAT)
						{
							TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store double " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType==Type.DOUBLE)
						{
							TextCode.add("store double " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType==Type.CONST_FLOAT)
						{
							String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
							String tempF2=Double.toString($b.theInfo.theVar.fValue);
							if(tempF2.length()>7)
							{
								long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
								tempF=Long.toHexString(tempL);
							}
							TextCode.add("store double " + tempF + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
					}
					else if($type.attr_type == Type.FLOAT) { 
						if($b.theInfo.theType == Type.INT)
						{
							TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store float " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType == Type.CONST_INT)
						{
							String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
							TextCode.add("store float " + tempf + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType==Type.LONG)
						{	
							TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store float " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType==Type.FLOAT)
						{
							TextCode.add("store float " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType==Type.DOUBLE)
						{
							TextCode.add("\%" + "t" + varCount + " = fptrunc double " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store float " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($b.theInfo.theType==Type.CONST_FLOAT)
						{
							String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
							String tempF2=Double.toString($b.theInfo.theVar.fValue);
							if(tempF2.length()>7)
							{
								long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
								tempF=Long.toHexString(tempL);
							}
							TextCode.add("store float " + tempF + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
					}
					else if($type.attr_type == Type.LONG) { 
						if($b.theInfo.theType == Type.INT)
						{
							TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType == Type.CONST_INT)
						{
							TextCode.add("store i64 " + $b.theInfo.theVar.iValue + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType==Type.LONG)
						{	
							TextCode.add("store i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType==Type.FLOAT)
						{
							TextCode.add("\%" + "t" + varCount + " = fptosi float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType==Type.DOUBLE)
						{
							TextCode.add("\%" + "t" + varCount + " = fptosi double " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
							$b.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($b.theInfo.theType==Type.CONST_FLOAT)
						{
							double tempd=$b.theInfo.theVar.fValue;
							TextCode.add("store i64 " + (long)tempd + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
					}
				}
			}
           } 
           (',' c=ID {arrvalue=0;} ('[' d=Integer_constant ']' {arrvalue=1;assvalue=0;})? ('=' e=arith_expression {assvalue=1;})? 
           {
			the_entry.theType = $type.attr_type;
			the_entry.theVar.varIndex = varCount;
			varCount ++;

			if (arrvalue==0) { 
				if ($type.attr_type == Type.INT) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
				}
				else if($type.attr_type == Type.DOUBLE) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca double, align 8");
				}
				else if($type.attr_type == Type.FLOAT) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca float, align 4");
				}
				else if($type.attr_type == Type.LONG) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " = alloca i64, align 8");
				}
			}
			else if(arrvalue==1){ 
				if ($type.attr_type == Type.INT) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " [ " + Integer.parseInt($d.text) +  " x i32], align 16");
				}
				else if($type.attr_type == Type.DOUBLE) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " [ " + Integer.parseInt($d.text) +  " x double], align 16");
				}
				else if($type.attr_type == Type.FLOAT) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " [ " + Integer.parseInt($d.text) +  " x float], align 16");
				}
				else if($type.attr_type == Type.LONG) { 
					TextCode.add("\%" + "t" + the_entry.theVar.varIndex + " [ " + Integer.parseInt($d.text) +  " x i64], align 16");
				}
				the_entry.theVar.arrSize=Integer.parseInt($d.text);
			}
			symtab.put($c.text, the_entry);
			if(assvalue==1) { 
				if (arrvalue==0) { 
					if ($type.attr_type == Type.INT) { 
						if($e.theInfo.theType == Type.INT)
						{
							TextCode.add("store i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType == Type.CONST_INT)
						{
							TextCode.add("store i32 " + $e.theInfo.theVar.iValue + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType==Type.LONG)
						{	
							TextCode.add("\%" + "t" + varCount + " = trunc i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to i32");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType==Type.FLOAT)
						{

							TextCode.add("\%" + "t" + varCount + " = fptosi float " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to i32");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType==Type.DOUBLE)
						{
							TextCode.add("\%" + "t" + varCount + " = fptosi double " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to i32");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType==Type.CONST_FLOAT)
						{
							double tempd=$e.theInfo.theVar.fValue;
							TextCode.add("store i32 " + (int)tempd + ", i32* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}				
					}
					else if($type.attr_type == Type.DOUBLE) { 
						if($e.theInfo.theType == Type.INT)
						{
							TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to double");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store double " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType == Type.CONST_INT)
						{
							String tempf=String.format("\%" + "6.6e",(double)$e.theInfo.theVar.iValue);
							TextCode.add("store double " + tempf + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType==Type.LONG)
						{	
							TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to double");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store double " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType==Type.FLOAT)
						{
							TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to double");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store double " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType==Type.DOUBLE)
						{
							TextCode.add("store double " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType==Type.CONST_FLOAT)
						{
							String tempF=String.format("\%" + "6.6e",$e.theInfo.theVar.fValue);
							String tempF2=Double.toString($b.theInfo.theVar.fValue);
							if(tempF2.length()>7)
							{
								long tempL=Double.doubleToLongBits($e.theInfo.theVar.fValue);
								tempF=Long.toHexString(tempL);
							}
							TextCode.add("store double " + tempF + ", double* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
					}
					else if($type.attr_type == Type.FLOAT) { 
						if($e.theInfo.theType == Type.INT)
						{
							TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to float");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store float " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType == Type.CONST_INT)
						{
							String tempf=String.format("\%" + "6.6e",(double)$e.theInfo.theVar.iValue);
							TextCode.add("store float " + tempf + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType==Type.LONG)
						{	
							TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to float");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store float " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType==Type.FLOAT)
						{
							TextCode.add("store float " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType==Type.DOUBLE)
						{
							TextCode.add("\%" + "t" + varCount + " = fptrunc double " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to float");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store float " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
						else if($e.theInfo.theType==Type.CONST_FLOAT)
						{
							String tempF=String.format("\%" + "6.6e",$e.theInfo.theVar.fValue);
							String tempF2=Double.toString($b.theInfo.theVar.fValue);
							if(tempF2.length()>7)
							{
								long tempL=Double.doubleToLongBits($e.theInfo.theVar.fValue);
								tempF=Long.toHexString(tempL);
							}
							TextCode.add("store float " + tempF + ", float* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 4");
						}
					}
					else if($type.attr_type == Type.LONG) { 
						if($e.theInfo.theType == Type.INT)
						{
							TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to i64");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType == Type.CONST_INT)
						{
							TextCode.add("store i64 " + $e.theInfo.theVar.iValue + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType==Type.LONG)
						{	
							TextCode.add("store i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType==Type.FLOAT)
						{
							TextCode.add("\%" + "t" + varCount + " = fptosi float " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to i64");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType==Type.DOUBLE)
						{
							TextCode.add("\%" + "t" + varCount + " = fptosi double " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to i64");
							$e.theInfo.theVar.varIndex=varCount;
							varCount+=1;
							TextCode.add("store i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
						else if($e.theInfo.theType==Type.CONST_FLOAT)
						{
							double tempd=$e.theInfo.theVar.fValue;
							TextCode.add("store i64 " + (long)tempd + ", i64* " + "\%" + "t" + the_entry.theVar.varIndex + ", align 8");
						}
					}
				}
			}

           } )*
           {arrvalue=0;assvalue=0;}
	    	;

type returns [Type attr_type]
	: INT { $attr_type=Type.INT;} 
	| FLOAT { $attr_type=Type.FLOAT;}
	| LONG { $attr_type=Type.LONG;}
	| DOUBLE { $attr_type=Type.DOUBLE;}
	| VOID { $attr_type=Type.VOID;}
	;

givevalue_statements returns [Info theInfo]
@init {
	theInfo = new Info();
	int larr_v=0;
	int rarr_v=0;
	}
	: ID {theInfo=symtab.get($ID.text);} ('[' Integer_constant ']' {larr_v=1;})?( '=' b=arith_expression 
							{
									if(arrvalue==1)
									{ 
										rarr_v=1; 
									}
									Type the_type = $theInfo.theType;
									
									if(the_type==Type.INT && $b.theInfo.theType==Type.CONST_INT)
									{
										TextCode.add("store i32 " + $b.theInfo.theVar.iValue + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $b.theInfo.theType==Type.CONST_INT)
									{
										TextCode.add("store i64 " + $b.theInfo.theVar.iValue + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.CONST_INT)
									{
										String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
										TextCode.add("store float " + tempf + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.CONST_INT)
									{
										String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
										TextCode.add("store double " + tempf + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $b.theInfo.theType==Type.INT)
									{
										TextCode.add("store i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $b.theInfo.theType==Type.LONG)
									{	

										TextCode.add("\%" + "t" + varCount + " = trunc i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i32");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $b.theInfo.theType==Type.INT)
									{
										TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $b.theInfo.theType==Type.FLOAT)
									{

										TextCode.add("\%" + "t" + varCount + " = fptosi float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i32");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.INT)
									{
										TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store float " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $b.theInfo.theType==Type.DOUBLE)
									{
										TextCode.add("\%" + "t" + varCount + " = fptosi double " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i32");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.INT)
									{
										TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store double " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $b.theInfo.theType==Type.CONST_FLOAT)
									{
										double tempd=$b.theInfo.theVar.fValue;
										TextCode.add("store i32 " + (int)tempd + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $b.theInfo.theType==Type.LONG)
									{
										TextCode.add("store i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $b.theInfo.theType==Type.FLOAT)
									{
										TextCode.add("\%" + "t" + varCount + " = fptosi float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.LONG)
									{
										TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store float " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $b.theInfo.theType==Type.DOUBLE)
									{
										TextCode.add("\%" + "t" + varCount + " = fptosi double " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.LONG)
									{
										TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store double " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $b.theInfo.theType==Type.CONST_FLOAT)
									{
										double tempd=$b.theInfo.theVar.fValue;
										TextCode.add("store i64 " + (long)tempd + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.FLOAT)
									{
										TextCode.add("store float " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.CONST_FLOAT)
									{
										String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
										String tempF2=Double.toString($b.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("store float " + tempF + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.CONST_FLOAT)
									{
										String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
										String tempF2=Double.toString($b.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("store double " + tempF + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.DOUBLE)
									{
										TextCode.add("store double " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.DOUBLE)
									{
										TextCode.add("\%" + "t" + varCount + " = fptrunc double " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
										TextCode.add("store float " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.FLOAT)
									{
											TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
											$b.theInfo.theVar.varIndex=varCount;
											varCount+=1;
											TextCode.add("store double " + "\%" + "t" + $b.theInfo.theVar.varIndex + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
							
							}
	
						   |ASSP_CH d=arith_expression
							{
														
									Type the_type = $theInfo.theType;
										

									if(the_type==Type.INT && $d.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = add nsw i32 " + "\%" + "t" + varCount + ", " + $d.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $d.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = add nsw i64 " + "\%" + "t" + varCount + ", " + $d.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $d.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempf=String.format("\%" + "6.6e",(double)$d.theInfo.theVar.iValue);
				   						TextCode.add("\%" + "t" + tempc + " = fadd float " + "\%" + "t" + varCount + ", " + tempf);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $d.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempf=String.format("\%" + "6.6e",(double)$d.theInfo.theVar.iValue);
				   						TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + tempf);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $d.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = add nsw i32 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $d.theInfo.theType==Type.LONG)
									{	
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sext i32 " + "\%" + "t" + varCount + " to i64");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = add nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = trunc i64 " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $d.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sext i32 " + "\%" + "t" + $d.theInfo.theVar.varIndex + " to i64");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = add nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $d.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex  + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to float");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fadd float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fptosi float " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $d.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex  + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sitofp i32 " + "\%" + "t" + $d.theInfo.theVar.varIndex + " to float");
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fadd float " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $d.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $d.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;
										TextCode.add("\%" + "t" + tempb + " = sitofp i32 " + "\%" + "t" + $d.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $d.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$d.theInfo.theVar.fValue);
										String tempF2=Double.toString($d.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($d.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + tempF);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $d.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = add nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $d.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to float");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fadd float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi float " + "\%" + "t" + varCount + " to i64");
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $d.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempb=varCount+1;
										TextCode.add("\%" + "t" + tempb + " = sitofp i64 " + "\%" + "t" + $d.theInfo.theVar.varIndex + " to float");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fadd float " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);

										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $d.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
			       						varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i64");
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $d.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sitofp i64 " + "\%" + "t" + $d.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
			       						varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $d.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}

										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$d.theInfo.theVar.fValue);
										String tempF2=Double.toString($d.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($d.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + tempF);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $d.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fadd float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
			       
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $d.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fpext float " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;

										String tempF=String.format("\%" + "6.6e",$d.theInfo.theVar.fValue);
										String tempF2=Double.toString($d.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($d.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + tempF);
			       
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $d.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$d.theInfo.theVar.fValue);
										String tempF2=Double.toString($d.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($d.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + tempF);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $d.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue );
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
			       
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $d.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fpext float " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptrunc double " + "\%" + "t" + varCount + " to float");
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $d.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = fpext float " + "\%" + "t" + $d.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fadd double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
							
							} 
						   |ASSD_CH e=arith_expression
						    {
														
								Type the_type = $theInfo.theType;

									if(the_type==Type.INT && $e.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sdiv i32 " + "\%" + "t" + varCount + ", " + $e.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $e.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sdiv i64 " + "\%" + "t" + varCount + ", " + $e.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $e.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempf=String.format("\%" + "6.6e",(double)$e.theInfo.theVar.iValue);
				   						TextCode.add("\%" + "t" + tempc + " = fdiv float " + "\%" + "t" + varCount + ", " + tempf);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $e.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempf=String.format("\%" + "6.6e",(double)$e.theInfo.theVar.iValue);
				   						TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + tempf);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $e.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sdiv i32 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $e.theInfo.theType==Type.LONG)
									{	
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sext i32 " + "\%" + "t" + varCount + " to i64");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sdiv i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = trunc i64 " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $e.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sext i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to i64");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = sdiv i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $e.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to float");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fptosi float " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $e.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sitofp i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to float");
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv float " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $e.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $e.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;
										TextCode.add("\%" + "t" + tempb + " = sitofp i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $e.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$e.theInfo.theVar.fValue);
										String tempF2=Double.toString($e.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($e.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + tempF);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $e.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sdiv i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $e.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to float");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi float " + "\%" + "t" + varCount + " to i64");
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $e.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempb=varCount+1;
										TextCode.add("\%" + "t" + tempb + " = sitofp i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to float");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv float " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $e.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
			       						varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i64");
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $e.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sitofp i64 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
			       						varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $e.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}

										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$e.theInfo.theVar.fValue);
										String tempF2=Double.toString($e.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($e.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + tempF);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $e.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
			       
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $e.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fpext float " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;

										String tempF=String.format("\%" + "6.6e",$e.theInfo.theVar.fValue);
										String tempF2=Double.toString($e.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($e.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + tempF);
			       
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $e.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$e.theInfo.theVar.fValue);
										String tempF2=Double.toString($e.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($e.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + tempF);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $e.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
			       
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $e.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fpext float " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptrunc double " + "\%" + "t" + varCount + " to float");
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $e.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = fpext float " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fdiv double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
							
							} 
						   |ASSMU_CH f=arith_expression
						    {
														
								Type the_type = $theInfo.theType;

									if(the_type==Type.INT && $f.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = mul nsw i32 " + "\%" + "t" + varCount + ", " + $f.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $f.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = mul nsw i64 " + "\%" + "t" + varCount + ", " + $f.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempf=String.format("\%" + "6.6e",(double)$f.theInfo.theVar.iValue);
				   						TextCode.add("\%" + "t" + tempc + " = fmul float " + "\%" + "t" + varCount + ", " + tempf);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempf=String.format("\%" + "6.6e",(double)$f.theInfo.theVar.iValue);
				   						TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + tempf);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $f.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = mul nsw i32 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $f.theInfo.theType==Type.LONG)
									{	
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sext i32 " + "\%" + "t" + varCount + " to i64");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = mul nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = trunc i64 " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $f.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sext i32 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to i64");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = mul nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $f.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to float");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fmul float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fptosi float " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sitofp i32 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to float");
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fmul float " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $f.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;
										TextCode.add("\%" + "t" + tempb + " = sitofp i32 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $f.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$f.theInfo.theVar.fValue);
										String tempF2=Double.toString($f.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($f.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + tempF);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $f.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = mul nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $f.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to float");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fmul float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi float " + "\%" + "t" + varCount + " to i64");
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempb=varCount+1;
										TextCode.add("\%" + "t" + tempb + " = sitofp i64 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to float");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fmul float " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $f.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
			       						varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i64");
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sitofp i64 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
			       						varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $f.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}

										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$f.theInfo.theVar.fValue);
										String tempF2=Double.toString($f.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($f.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + tempF);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fmul float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
			       
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = , [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fpext float " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;

										String tempF=String.format("\%" + "6.6e",$f.theInfo.theVar.fValue);
										String tempF2=Double.toString($f.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($f.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + tempF);
			       
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$f.theInfo.theVar.fValue);
										String tempF2=Double.toString($f.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($f.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + tempF);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
			       
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fpext float " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptrunc double " + "\%" + "t" + varCount + " to float");
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = fpext float " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fmul double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
							
							}
						   |ASSMI_CH g=arith_expression
						    {
														
								Type the_type = $theInfo.theType;

									if(the_type==Type.INT && $g.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sub nsw i32 " + "\%" + "t" + varCount + ", " + $g.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $g.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sub nsw i64 " + "\%" + "t" + varCount + ", " + $g.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempf=String.format("\%" + "6.6e",(double)$g.theInfo.theVar.iValue);
				   						TextCode.add("\%" + "t" + tempc + " = fsub float " + "\%" + "t" + varCount + ", " + tempf);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.CONST_INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempf=String.format("\%" + "6.6e",(double)$g.theInfo.theVar.iValue);
				   						TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + tempf);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $g.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sub nsw i32 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $g.theInfo.theType==Type.LONG)
									{	
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sext i32 " + "\%" + "t" + varCount + " to i64");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sub nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = trunc i64 " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $g.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sext i32 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to i64");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = sub nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $g.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to float");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fsub float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fptosi float " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sitofp i32 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to float");
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fsub float " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.INT && $g.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.INT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;
										TextCode.add("\%" + "t" + tempb + " = sitofp i32 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.INT && $g.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}       
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = sitofp i32 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$g.theInfo.theVar.fValue);
										String tempF2=Double.toString($g.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($g.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + tempF);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i32");
										varCount=tempc+1;
										TextCode.add("store i32 " + "\%" + "t" + tempc + ", i32* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $g.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sub nsw i64 " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.iValue);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $g.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to float");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fsub float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi float " + "\%" + "t" + varCount + " to i64");
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempb=varCount+1;
										TextCode.add("\%" + "t" + tempb + " = sitofp i64 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to float");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fsub float " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.LONG && $g.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
			       						varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptosi double " + "\%" + "t" + varCount + " to i64");
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.LONG)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = sitofp i64 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
			       						varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.LONG && $g.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}

										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = sitofp i64 " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$g.theInfo.theVar.fValue);
										String tempF2=Double.toString($g.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($g.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + tempF);
										varCount=tempc+1;
										TextCode.add("store i64 " + "\%" + "t" + tempc + ", i64* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fsub float " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
			       						varCount=tempc+1;

										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;

										TextCode.add("\%" + "t" + tempc + " = fpext float " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;

										String tempF=String.format("\%" + "6.6e",$g.theInfo.theVar.fValue);
										String tempF2=Double.toString($g.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($g.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + tempF);
			       
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.CONST_FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										String tempF=String.format("\%" + "6.6e",$g.theInfo.theVar.fValue);
										String tempF2=Double.toString($g.theInfo.theVar.fValue);
										if(tempF2.length()>7)
										{
											long tempL=Double.doubleToLongBits($g.theInfo.theVar.fValue);
											tempF=Long.toHexString(tempL);
										}
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + tempF);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
			       
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
									else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.DOUBLE)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
											varCount+=1;
										}
										int tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fpext float " + "\%" + "t" + varCount + " to double");
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
										varCount+=1;
										tempc=varCount+1;
										TextCode.add("\%" + "t" + tempc + " = fptrunc double " + "\%" + "t" + varCount + " to float");
										varCount=tempc+1;
										TextCode.add("store float " + "\%" + "t" + tempc + ", float* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 4");
									}
									else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.FLOAT)
									{
										if(larr_v==0){
											TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
										}
										else if(larr_v==1) {
											int arrIndex=$theInfo.theVar.arrSize;
											TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + $theInfo.theVar.varIndex + ", i64 0, i64 " + $theInfo.theVar.iValue);
											TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
											varCount+=1;
										}
										int tempb=varCount+1;

										TextCode.add("\%" + "t" + tempb + " = fpext float " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
										int tempc=tempb+1;
										TextCode.add("\%" + "t" + tempc + " = fsub double " + "\%" + "t" + varCount + ", " + "\%" + "t" + tempb);
										varCount=tempc+1;
										TextCode.add("store double " + "\%" + "t" + tempc + ", double* " + "\%" + "t" + $theInfo.theVar.varIndex + ", align 8");
									}
							
							}
	)
    ';' ;

   
statements:statement  statements
        |;

arith_expression returns [Info theInfo]
@init {theInfo = new Info();}
	: a=multExpr {$theInfo=$a.theInfo;} 
	( ('+' b=multExpr) 
	{
				Type the_type = $theInfo.theType;
				
			   if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue+=$b.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.CONST_INT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.FLOAT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + tempf + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.CONST_INT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.DOUBLE)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + tempf + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.fValue+=$b.theInfo.theVar.iValue;
				   
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.CONST_FLOAT)
			   {
				   $theInfo.theVar.fValue=$theInfo.theVar.iValue+$b.theInfo.theVar.fValue;
				   $theInfo.theType=Type.CONST_FLOAT;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = add nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = add nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.CONST_FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
				   String tempF2=Double.toString($b.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.CONST_FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
				   String tempF2=Double.toString($b.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.FLOAT && $b.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $b.theInfo.theType==Type.CONST_FLOAT))
			   {
				   if(the_type==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
				   String tempF2=Double.toString($b.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.DOUBLE))
			   {
				   if($b.theInfo.theType==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.DOUBLE && $b.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $b.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $b.theInfo.theType==Type.FLOAT))
			   {
				   if(the_type==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   else if($b.theInfo.theType==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
						$b.theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.CONST_FLOAT)
			   {
				   $theInfo.theVar.fValue+=$b.theInfo.theVar.fValue;
			   }
	}
	| ('-' c=multExpr) 
	{
				Type the_type = $theInfo.theType;
				
			   if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue-=$c.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sub nsw i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sub nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sub nsw i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.CONST_INT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$c.theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fsub float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.FLOAT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fsub float " + tempf + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.CONST_INT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$c.theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.DOUBLE)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + tempf + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.fValue-=$c.theInfo.theVar.iValue;
				   
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.CONST_FLOAT)
			   {
				   $theInfo.theVar.fValue=$theInfo.theVar.iValue-$c.theInfo.theVar.fValue;
				   $theInfo.theType=Type.CONST_FLOAT;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sub nsw i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = sub nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to i64");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = sub nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fsub float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to float");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fsub float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.CONST_FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
				   String tempF2=Double.toString($c.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sub nsw i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fsub float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to float");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fsub float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.CONST_FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
				   String tempF2=Double.toString($c.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = fsub float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.FLOAT && $c.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $c.theInfo.theType==Type.CONST_FLOAT))
			   {
				   if(the_type==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
				   String tempF2=Double.toString($c.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.DOUBLE))
			   {
				   if($c.theInfo.theType==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.DOUBLE && $c.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $c.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $c.theInfo.theType==Type.FLOAT))
			   {
				   if(the_type==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   else if($c.theInfo.theType==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
						$c.theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   TextCode.add("\%" + "t" + varCount + " = fsub double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.CONST_FLOAT)
			   {
				   $theInfo.theVar.fValue-=$c.theInfo.theVar.fValue;
			   }
	}
	| ('^' d=multExpr) 
	{
				Type the_type = $theInfo.theType;
			   if(the_type==Type.CONST_INT && $d.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue^=$d.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $d.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = xor i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $d.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = xor i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $d.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $d.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = xor i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $d.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $d.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = xor i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $d.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = xor i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $d.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = xor i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $d.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $d.theInfo.theVar.varIndex + " to i64");
				   $d.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = xor i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $d.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $d.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = xor i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $d.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }

	}
	| ('|' e=multExpr) 
	{
				Type the_type = $theInfo.theType;
			   if(the_type==Type.CONST_INT && $e.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue|=$e.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $e.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = or i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $e.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = or i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $e.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $e.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = or i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $e.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $e.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = or i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $e.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = or i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $e.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = or i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $e.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $e.theInfo.theVar.varIndex + " to i64");
				   $e.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = or i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $e.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $e.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = or i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $e.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }

	}
	| ('&' f=multExpr) 
	{
				Type the_type = $theInfo.theType;
			   if(the_type==Type.CONST_INT && $f.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue &= $f.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $f.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = and i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $f.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = and i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $f.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $f.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = and i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $f.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $f.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = and i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $f.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = and i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $f.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = and i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $f.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to i64");
				   $f.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = and i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $f.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = and i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $f.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }

	}
	| (RSHIFT_OP g=multExpr) 
	{
				Type the_type = $theInfo.theType;
			   if(the_type==Type.CONST_INT && $g.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue <<= $g.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $g.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = shl i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $g.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = shl i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $g.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $g.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = shl i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $g.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $g.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = shl i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $g.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = shl i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $g.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = shl i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $g.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to i64");
				   $g.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = shl i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $g.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = shl i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $g.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }

	}
	| (LSHIFT_OP  h=multExpr)  
	{
				Type the_type = $theInfo.theType;
			   if(the_type==Type.CONST_INT && $h.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue >>= $h.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $h.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = ashr i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $h.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = ashr i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $h.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $h.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = ashr i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $h.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $h.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = ashr i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $h.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = ashr i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $h.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = ashr i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $h.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to i64");
				   $h.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = ashr i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $h.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = ashr i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $h.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }

	}  )*
	;


multExpr returns [Info theInfo]
@init {theInfo = new Info();}
	: a=primaryExpr {$theInfo=$a.theInfo;}
          ( ('*' b=primaryExpr {

				Type the_type = $theInfo.theType;
				
			   if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue*=$b.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = mul nsw i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = mul nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = mul nsw i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.CONST_INT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fmul float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.FLOAT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fmul float " + tempf + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.CONST_INT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.DOUBLE)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + tempf + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.fValue*=$b.theInfo.theVar.iValue;
				   
			   }
			   else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.CONST_FLOAT)
			   {
				   $theInfo.theVar.fValue=$theInfo.theVar.iValue*$b.theInfo.theVar.fValue;
				   $theInfo.theType=Type.CONST_FLOAT;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = mul nsw i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = mul nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = mul nsw i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fmul float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fmul float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $b.theInfo.theType==Type.CONST_FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
				   String tempF2=Double.toString($b.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = mul nsw i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fmul float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fmul float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $b.theInfo.theType==Type.CONST_FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
				   String tempF2=Double.toString($b.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
				   $b.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = fmul float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.FLOAT && $b.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $b.theInfo.theType==Type.CONST_FLOAT))
			   {
				   if(the_type==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
				   String tempF2=Double.toString($b.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.DOUBLE))
			   {
				   if($b.theInfo.theType==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.DOUBLE && $b.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $b.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $b.theInfo.theType==Type.FLOAT))
			   {
				   if(the_type==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   else if($b.theInfo.theType==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
						$b.theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   TextCode.add("\%" + "t" + varCount + " = fmul double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.CONST_FLOAT)
			   {
				   $theInfo.theVar.fValue*=$b.theInfo.theVar.fValue;
			   }
		  })
          | ('/' c=primaryExpr {
			  Type the_type = $theInfo.theType;
				
			   if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.iValue/=$c.theInfo.theVar.iValue;
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sdiv i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			   	   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sdiv i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.CONST_INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sdiv i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sdiv i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.CONST_INT)
			   {

				   String tempf=String.format("\%" + "6.6e",(double)$c.theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fdiv float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.FLOAT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fdiv float " + tempf + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.CONST_INT)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$c.theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.DOUBLE)
			   {
				   String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + tempf + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.CONST_INT)
			   {
				   $theInfo.theVar.fValue/=$c.theInfo.theVar.iValue;
				   
			   }
			   else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.CONST_FLOAT)
			   {
				   $theInfo.theVar.fValue=$theInfo.theVar.iValue/$c.theInfo.theVar.fValue;
				   $theInfo.theType=Type.CONST_FLOAT;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sdiv i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = sdiv i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to i64");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = sdiv i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fdiv float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to float");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fdiv float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.INT && $c.theInfo.theType==Type.CONST_FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
				   String tempF2=Double.toString($c.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sdiv nsw i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.iValue);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fdiv float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to float");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fdiv float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.LONG && $c.theInfo.theType==Type.CONST_FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
				   $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
				   String tempF2=Double.toString($c.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
				   $c.theInfo.theVar.varIndex=varCount;
				   varCount+=1;
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = fdiv float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.FLOAT && $c.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $c.theInfo.theType==Type.CONST_FLOAT))
			   {
				   if(the_type==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
				   String tempF2=Double.toString($c.theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.DOUBLE))
			   {
				   if($c.theInfo.theType==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
				   String tempF2=Double.toString($theInfo.theVar.fValue);
				   if(tempF2.length()>7)
				   {
					   long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
					   tempF=Long.toHexString(tempL);
				   }
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if((the_type==Type.DOUBLE && $c.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $c.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $c.theInfo.theType==Type.FLOAT))
			   {
				   if(the_type==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
						$theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   else if($c.theInfo.theType==Type.FLOAT)
				   {
					    TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
						$c.theInfo.theVar.varIndex=varCount;
						varCount+=1;
				   }
				   TextCode.add("\%" + "t" + varCount + " = fdiv double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
			       $theInfo.theVar.varIndex=varCount;
				   varCount+=1;
			   }
			   else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.CONST_FLOAT)
			   {
				   $theInfo.theVar.fValue/=$c.theInfo.theVar.fValue;
			   }
		  })
		  )*
		  ;
		  
primaryExpr returns [Info theInfo]
@init {theInfo = new Info();}
	: a=atom {$theInfo=$a.theInfo;}
           | LPAR_CH d=arith_expression RPAR_CH {$theInfo=$d.theInfo;}
           | f=atom PP_OP {
			   $theInfo=$f.theInfo;
			   int vIndex=$theInfo.theVar.varIndex;
			   Type the_type = $theInfo.theType;
			   int oIndex=symtab.get($theInfo.theVar.varID).theVar.varIndex;
			   if(the_type==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i32 " + "\%" + "t" + vIndex + ", 1");
				   TextCode.add("store i32 " + "\%" + "t" + varCount + ", i32* " + "\%" + "t" + oIndex + ", align 4");
			   }
			   else if(the_type==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i64 " + "\%" + "t" + vIndex + ", 1");
				   TextCode.add("store i64 " + "\%" + "t" + varCount + ", i64* " + "\%" + "t" + oIndex + ", align 8");
			   }
			   else if(the_type==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + vIndex + ", 1.000000e+00");
				   TextCode.add("store double " + "\%" + "t" + varCount + ", double* " + "\%" + "t" + oIndex + ", align 8");
			   }
			   else if(the_type==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + "\%" + "t" + vIndex + ", 1.000000e+00");
				   TextCode.add("store float " + "\%" + "t" + varCount + ", float* " + "\%" + "t" + oIndex + ", align 4");
			   }
			   $theInfo.theVar.varIndex=varCount;
			   varCount+=1;
			}
           | g=atom MM_OP {
			   $theInfo=$g.theInfo;
			   int vIndex=$theInfo.theVar.varIndex;
			   Type the_type = $theInfo.theType;
			   int oIndex=symtab.get($theInfo.theVar.varID).theVar.varIndex;
			   if(the_type==Type.INT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i32 " + "\%" + "t" + vIndex + ", -1");
				   TextCode.add("store i32 " + "\%" + "t" + varCount + ", i32* " + "\%" + "t" + oIndex + ", align 4");
			   }
			   else if(the_type==Type.LONG)
			   {
				   TextCode.add("\%" + "t" + varCount + " = add nsw i64 " + "\%" + "t" + vIndex + ", -1");
				   TextCode.add("store i64 " + "\%" + "t" + varCount + ", i64* " + "\%" + "t" + oIndex + ", align 8");
			   }
			   else if(the_type==Type.DOUBLE)
			   {
				   TextCode.add("\%" + "t" + varCount + " = fadd double " + "\%" + "t" + vIndex + ", -1.000000e+00");
				   TextCode.add("store double " + "\%" + "t" + varCount + ", double* " + "\%" + "t" + oIndex + ", align 8");
			   }
			   else if(the_type==Type.FLOAT)
			   {
				   TextCode.add("\%" + "t" + varCount + " = fadd float " + "\%" + "t" + vIndex + ", -1.000000e+00");
				   TextCode.add("store float " + "\%" + "t" + varCount + ", float* " + "\%" + "t" + oIndex + ", align 4");
			   }
			   $theInfo.theVar.varIndex=varCount;
			   varCount+=1;
			}
           ;

atom returns [Info theInfo]
@init {theInfo = new Info();}
     : ID {arrvalue=0;} ('[' a=Integer_constant ']' {arrvalue=1;})? {
		 Type the_type = symtab.get($ID.text).theType;
		 $theInfo.theType = the_type;
		 int vIndex = symtab.get($ID.text).theVar.varIndex;
		
		switch (the_type) {
            case INT: 
                if(arrvalue==0){
					TextCode.add("\%" + "t" + varCount + " = load i32, i32* " + "\%" + "t" + vIndex + ", align 4");
				}       
				else if(arrvalue==1) {
					int arrIndex=symtab.get($ID.text).theVar.arrSize;
					TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + vIndex + ", i64 0, i64 " + Integer.parseInt($a.text));
					TextCode.add("\%" + "t" + (varCount+1) + " = load i32, i32* " + "\%" + "t" + varCount + ", align 4");
					varCount+=1;
				}
				$theInfo.theVar.varIndex = varCount;
				$theInfo.theVar.varID=$ID.text;
				varCount+=1;
                break;
            case FLOAT:
				if(arrvalue==0){
					TextCode.add("\%" + "t" + varCount + " = load float, float* " + "\%" + "t" + vIndex + ", align 4");
				}
				else if(arrvalue==1) {
					int arrIndex=symtab.get($ID.text).theVar.arrSize;
					TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + vIndex + ", i64 0, i64 " + Integer.parseInt($a.text));
					TextCode.add("\%" + "t" + (varCount+1) + " = load float, float* " + "\%" + "t" + varCount + ", align 4");
					varCount+=1;
				}
				$theInfo.theVar.varIndex = varCount;
				$theInfo.theVar.varID=$ID.text;
				varCount+=1;
                break;
            case DOUBLE:
				if(arrvalue==0){
					TextCode.add("\%" + "t" + varCount + " = load double, double* " + "\%" + "t" + vIndex + ", align 8");
				}
				else if(arrvalue==1) {
					int arrIndex=symtab.get($ID.text).theVar.arrSize;
					TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + vIndex + ", i64 0, i64 " + Integer.parseInt($a.text));
					TextCode.add("\%" + "t" + (varCount+1) + " = load double, double* " + "\%" + "t" + varCount + ", align 8");
					varCount+=1;
				}
				$theInfo.theVar.varIndex = varCount;
				$theInfo.theVar.varID=$ID.text;
				varCount+=1;
                break;
			case LONG:
				if(arrvalue==0){
					TextCode.add("\%" + "t" + varCount + " = load i64, i64* " + "\%" + "t" + vIndex + ", align 8");
				}
				else if(arrvalue==1) {
					int arrIndex=symtab.get($ID.text).theVar.arrSize;
					TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + vIndex + ", i64 0, i64 " + Integer.parseInt($a.text));
					TextCode.add("\%" + "t" + (varCount+1) + " = load i64, i64* " + "\%" + "t" + varCount + ", align 8");
					varCount+=1;
				}
				$theInfo.theVar.varIndex = varCount;
				$theInfo.theVar.varID=$ID.text;
				varCount+=1;
                break;
        }


       
       }
     |b=Integer_constant {
            $theInfo.theType = Type.CONST_INT;
			$theInfo.theVar.iValue = Integer.parseInt($b.text);
         }
     |Floating_point_constant  {
		$theInfo.theType = Type.CONST_FLOAT;		
		$theInfo.theVar.fValue = Double.parseDouble ($Floating_point_constant.text);
	 } ;

Integer_constant: ('0'..'9')+ ;
 
compare_expression returns [Info theInfo]
@init {theInfo = new Info();}
:  a=arith_expression {$theInfo=$a.theInfo;} (LT_CH b=arith_expression
					{
							Type the_type = $theInfo.theType;
								
							if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp slt i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $b.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp slt i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $b.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp slt i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp slt i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp olt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.FLOAT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp olt float " + tempf + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$b.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $b.theInfo.theType==Type.DOUBLE)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + tempf + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $b.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp slt i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $b.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp slt i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $b.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to i64");
								$b.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp slt i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $b.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp olt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
								$b.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp olt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $b.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
								$b.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $b.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
								String tempF2=Double.toString($b.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
								$b.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $b.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp slt i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $b.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $b.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp olt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to float");
								$b.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp olt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $b.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $b.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
								$b.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $b.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
								String tempF2=Double.toString($b.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
								$b.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $b.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = fcmp olt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.FLOAT && $b.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $b.theInfo.theType==Type.CONST_FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$b.theInfo.theVar.fValue);
								String tempF2=Double.toString($b.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($b.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $b.theInfo.theType==Type.DOUBLE))
							{
								if($b.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + tempF + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.DOUBLE && $b.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $b.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $b.theInfo.theType==Type.FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								else if($b.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $b.theInfo.theVar.varIndex + " to double");
										$b.theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp olt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $b.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}

					}
					| GT_CH c=arith_expression
					{

							Type the_type = $theInfo.theType;
								
							if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sgt i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $c.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sgt i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $c.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sgt i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sgt i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$c.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.FLOAT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt float " + tempf + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$c.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $c.theInfo.theType==Type.DOUBLE)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + tempf + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $c.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sgt i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $c.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp sgt i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $c.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to i64");
								$c.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp sgt i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $c.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to float");
								$c.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $c.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
								$c.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $c.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
								String tempF2=Double.toString($c.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
								$c.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $c.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sgt i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $c.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $c.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to float");
								$c.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $c.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $c.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
								$c.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $c.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
								String tempF2=Double.toString($c.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
								$c.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $c.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.FLOAT && $c.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $c.theInfo.theType==Type.CONST_FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$c.theInfo.theVar.fValue);
								String tempF2=Double.toString($c.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($c.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $c.theInfo.theType==Type.DOUBLE))
							{
								if($c.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + tempF + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.DOUBLE && $c.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $c.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $c.theInfo.theType==Type.FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								else if($c.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $c.theInfo.theVar.varIndex + " to double");
										$c.theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ogt double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $c.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}

					}
					| GE_OP f=arith_expression
					{

							Type the_type = $theInfo.theType;
								
							if(the_type==Type.CONST_INT && $f.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sge i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $f.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sge i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $f.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $f.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sge i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $f.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $f.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sge i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$f.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp oge float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $f.theInfo.theType==Type.FLOAT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp oge float " + tempf + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$f.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $f.theInfo.theType==Type.DOUBLE)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + tempf + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $f.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sge i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $f.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp sge i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $f.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to i64");
								$f.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp sge i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $f.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oge float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to float");
								$f.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oge float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $f.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
								$f.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $f.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$f.theInfo.theVar.fValue);
								String tempF2=Double.toString($f.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($f.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $f.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
								$f.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + tempF + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $f.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sge i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $f.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $f.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oge float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to float");
								$f.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oge float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $f.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $f.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
								$f.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $f.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$f.theInfo.theVar.fValue);
								String tempF2=Double.toString($f.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($f.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $f.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
								$f.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + tempF + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $f.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = fcmp oge float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.FLOAT && $f.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $f.theInfo.theType==Type.CONST_FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$f.theInfo.theVar.fValue);
								String tempF2=Double.toString($f.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($f.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.CONST_FLOAT && $f.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $f.theInfo.theType==Type.DOUBLE))
							{
								if($f.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + tempF + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.DOUBLE && $f.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $f.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $f.theInfo.theType==Type.FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								else if($f.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $f.theInfo.theVar.varIndex + " to double");
										$f.theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oge double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $f.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}

					}
					| LE_OP g=arith_expression
					{

							Type the_type = $theInfo.theType;
								
							if(the_type==Type.CONST_INT && $g.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sle i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $g.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sle i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $g.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $g.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sle i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $g.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $g.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sle i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$g.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp ole float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $g.theInfo.theType==Type.FLOAT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp ole float " + tempf + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$g.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $g.theInfo.theType==Type.DOUBLE)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + tempf + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $g.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sle i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $g.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp sle i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $g.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to i64");
								$g.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp sle i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $g.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ole float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to float");
								$g.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ole float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $g.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
								$g.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $g.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$g.theInfo.theVar.fValue);
								String tempF2=Double.toString($g.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($g.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $g.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
								$g.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + tempF + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $g.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp sle i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $g.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $g.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ole float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to float");
								$g.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ole float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $g.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $g.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
								$g.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $g.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$g.theInfo.theVar.fValue);
								String tempF2=Double.toString($g.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($g.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $g.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
								$g.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + tempF + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $g.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = fcmp ole float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.FLOAT && $g.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $g.theInfo.theType==Type.CONST_FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$g.theInfo.theVar.fValue);
								String tempF2=Double.toString($g.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($g.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.CONST_FLOAT && $g.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $g.theInfo.theType==Type.DOUBLE))
							{
								if($g.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + tempF + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.DOUBLE && $g.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $g.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $g.theInfo.theType==Type.FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								else if($g.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $g.theInfo.theVar.varIndex + " to double");
										$g.theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp ole double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $g.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}

					}
					| NE_OP h=arith_expression
					{

							Type the_type = $theInfo.theType;
								
							if(the_type==Type.CONST_INT && $h.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp ne i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $h.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp ne i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $h.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $h.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp ne i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $h.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $h.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp ne i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $h.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$h.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp une float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $h.theInfo.theType==Type.FLOAT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp une float " + tempf + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $h.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$h.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $h.theInfo.theType==Type.DOUBLE)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + tempf + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $h.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp ne i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $h.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp ne i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $h.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to i64");
								$h.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp ne i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $h.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp une float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $h.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to float");
								$h.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp une float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $h.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $h.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to double");
								$h.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $h.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$h.theInfo.theVar.fValue);
								String tempF2=Double.toString($h.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($h.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $h.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to double");
								$h.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + tempF + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $h.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp ne i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $h.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $h.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp une float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $h.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to float");
								$h.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp une float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $h.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $h.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to double");
								$h.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $h.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$h.theInfo.theVar.fValue);
								String tempF2=Double.toString($h.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($h.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $h.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to double");
								$h.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + tempF + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $h.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = fcmp une float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.FLOAT && $h.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $h.theInfo.theType==Type.CONST_FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$h.theInfo.theVar.fValue);
								String tempF2=Double.toString($h.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($h.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.CONST_FLOAT && $h.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $h.theInfo.theType==Type.DOUBLE))
							{
								if($h.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + tempF + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.DOUBLE && $h.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $h.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $h.theInfo.theType==Type.FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								else if($h.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $h.theInfo.theVar.varIndex + " to double");
										$h.theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp une double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $h.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}

					}
					| EQ_OP i=arith_expression
					{

							Type the_type = $theInfo.theType;
								
							if(the_type==Type.CONST_INT && $i.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp eq i32 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $i.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp eq i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $i.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $i.theInfo.theType==Type.CONST_INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp eq i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + $i.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $i.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp eq i64 " + $theInfo.theVar.iValue + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $i.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$i.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $i.theInfo.theType==Type.FLOAT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq float " + tempf + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $i.theInfo.theType==Type.CONST_INT)
							{
								String tempf=String.format("\%" + "6.6e",(double)$i.theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempf);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_INT && $i.theInfo.theType==Type.DOUBLE)
							{
								String tempf=String.format("\%" + "6.6e",(double)$theInfo.theVar.iValue);
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + tempf + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $i.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp eq i32 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $i.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to i64");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp eq i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $i.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sext i32 " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to i64");
								$i.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = icmp eq i64 " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $i.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $i.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to float");
								$i.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $i.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $i.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to double");
								$i.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.INT && $i.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$i.theInfo.theVar.fValue);
								String tempF2=Double.toString($i.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($i.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $i.theInfo.theType==Type.INT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i32 " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to double");
								$i.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + tempF + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $i.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = icmp eq i64 " + "\%" + "t" + $theInfo.theVar.iValue + ", " + "\%" + "t" + $i.theInfo.theVar.iValue);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $i.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to float");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $i.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to float");
								$i.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $i.theInfo.theType==Type.DOUBLE)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.DOUBLE && $i.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to double");
								$i.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.LONG && $i.theInfo.theType==Type.CONST_FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$i.theInfo.theVar.fValue);
								String tempF2=Double.toString($i.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($i.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.CONST_FLOAT && $i.theInfo.theType==Type.LONG)
							{
								TextCode.add("\%" + "t" + varCount + " = sitofp i64 " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to double");
								$i.theInfo.theVar.varIndex=varCount;
								varCount+=1;
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + tempF + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if(the_type==Type.FLOAT && $i.theInfo.theType==Type.FLOAT)
							{
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq float " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.FLOAT && $i.theInfo.theType==Type.CONST_FLOAT)||(the_type==Type.DOUBLE && $i.theInfo.theType==Type.CONST_FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$i.theInfo.theVar.fValue);
								String tempF2=Double.toString($i.theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($i.theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + tempF);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.CONST_FLOAT && $i.theInfo.theType==Type.FLOAT)||(the_type==Type.CONST_FLOAT && $i.theInfo.theType==Type.DOUBLE))
							{
								if($i.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								String tempF=String.format("\%" + "6.6e",$theInfo.theVar.fValue);
								String tempF2=Double.toString($theInfo.theVar.fValue);
								if(tempF2.length()>7)
								{
									long tempL=Double.doubleToLongBits($theInfo.theVar.fValue);
									tempF=Long.toHexString(tempL);
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + tempF + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}
							else if((the_type==Type.DOUBLE && $i.theInfo.theType==Type.DOUBLE)||(the_type==Type.FLOAT && $i.theInfo.theType==Type.DOUBLE)||(the_type==Type.DOUBLE && $i.theInfo.theType==Type.FLOAT))
							{
								if(the_type==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $theInfo.theVar.varIndex + " to double");
										$theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								else if($i.theInfo.theType==Type.FLOAT)
								{
										TextCode.add("\%" + "t" + varCount + " = fpext float " + "\%" + "t" + $i.theInfo.theVar.varIndex + " to double");
										$i.theInfo.theVar.varIndex=varCount;
										varCount+=1;
								}
								TextCode.add("\%" + "t" + varCount + " = fcmp oeq double " + "\%" + "t" + $theInfo.theVar.varIndex + ", " + "\%" + "t" + $i.theInfo.theVar.varIndex);
								$theInfo.theVar.varIndex=varCount;
								varCount+=1;
							}

					} ) ;

statement: givevalue_statements
         | if_then_statements
         | arith_expression ';'
         | return_statements
         | scanf_statements
         | printf_statements
         | declarations
		 ;


printf_statements: PRINTF {if(printValue==0){TextCode.add(0,"declare dso_local i32 @printf(i8*, ...)");printValue=1;}} '(' a=STRING {
			String tempa=($a.text);
			char[] tempb=new char[2*tempa.length()+2];
			int cnt=0;
			int templ=0;
			for(int i=0;i<tempa.length();i++)
			{ 
				if(i==tempa.indexOf("\\n",i))
				{
					tempb[cnt]='\\';
					tempb[cnt+1]='0';
					tempb[cnt+2]='A';
					cnt+=3;
					templ+=1;
					i+=1;
				}
				else if(i==tempa.length()-1)
				{
					tempb[cnt]='\\';
					tempb[cnt+1]='0';
					tempb[cnt+2]='0';
					tempb[cnt+3]='"';
					cnt+=4;
					templ+=1;
				}
				else
				{
					tempb[cnt]=tempa.charAt(i);
					if(i!=0)
					{
						templ+=1;
					}
					cnt+=1;
					
				}
			}
			printStr=String.valueOf(tempb);
			printStr=printStr.substring(0,cnt);
			TextCode.add(0,"@.str." + strCount + " = private unnamed_addr constant [" + templ + " x i8] c" + printStr + ", align 1");
			
		} (',' b=arith_expression {
										
											Info ae=$b.theInfo;
											String tempt="";
											if(ae.theType==Type.INT)
											{
												tempt="i32";
											}
											else if(ae.theType==Type.LONG)
											{
												tempt="i64";
											}
											else if(ae.theType==Type.FLOAT)
											{
												tempt="float";
											}
											else if(ae.theType==Type.DOUBLE)
											{
												tempt="double";
											}
											printPara+=", " + tempt + " \%" + "t" +ae.theVar.varIndex;
										})* ')' ';' {
										TextCode.add("\%" + "t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([" + templ + " x i8], [" + templ + " x i8]* @.str." + strCount + ", i64 0, i64 0)" + printPara + ")");
										printPara="";
										printStr="";
										strCount+=1;
										varCount+=1;
										};

//printf scanf may occur problem, cannot store textcode.size(), store the last element
if_then_statements: IF {String l_ele="";} '(' a=compare_expression {
								l_ele=TextCode.get(TextCode.size()-1);
								ifpMap.put(ifcnt,l_ele);
								ifcMap.put(ifcnt,$a.theInfo);
								conArr.add(ifcnt);ifcnt+=1;} ')'  '{' statements {
									l_ele=TextCode.get(TextCode.size()-1);
									ifpMap.put(ifcnt,l_ele);
									staArr.add(ifcnt);
									ifcnt+=1;} '}' (ELSE IF '(' b=compare_expression {
										l_ele=TextCode.get(TextCode.size()-1);
										ifpMap.put(ifcnt,l_ele);
										ifcMap.put(ifcnt,$b.theInfo);
										conArr.add(ifcnt);
										ifcnt+=1;} ')'  '{' statements {
											l_ele=TextCode.get(TextCode.size()-1);
											ifpMap.put(ifcnt,l_ele);
											staArr.add(ifcnt);ifcnt+=1;} '}' )* (ELSE '{' statements {
												l_ele=TextCode.get(TextCode.size()-1);
												ifpMap.put(ifcnt,l_ele);
												conArr.add(ifcnt);
												elsevalue=ifcnt;
												ifcnt+=1;} '}')?   
							{
								
								int a_size=conArr.size();
								int t_bnum=conArr.size()+2*staArr.size()-1;
								int n_bnum=t_bnum;
								for(int i=0;i<a_size;i+=1)
								{
									int num=conArr.get(i);
									String temps=ifpMap.get(num);
									int tempp=TextCode.indexOf(temps)+1;					
									TextCode.add(tempp,"b" + (num+1) + ":");
									TextCode.add(tempp,"\n");
									if(elsevalue!=-1 && i==a_size-1)
									{
										TextCode.add(tempp,"br label " + "\%" + "b" + n_bnum);
									}
									else
									{
										int cpos=(ifcMap.get(num)).theVar.varIndex;
										if(i==a_size-1)
										{
											TextCode.add(tempp,"br i1 " + "\%" + "t" + cpos + ", label " + "\%" + "b" + staArr.get(i) + ", label " + "\%" + "b" + n_bnum);
										}
										else
										{
											TextCode.add(tempp,"br i1 " + "\%" + "t" + cpos + ", label " + "\%" + "b" + staArr.get(i) + ", label " + "\%" + "b" + conArr.get(i+1));
										}
										num=staArr.get(i);
										temps=ifpMap.get(num);
										tempp=TextCode.indexOf(temps)+1;	
										TextCode.add(tempp,"b" + (num+1) + ":");//this is the line written by me, not my block
										TextCode.add(tempp,"\n");
										TextCode.add(tempp,"br label " + "\%" + "b" + n_bnum);
										if(i<staArr.size()-1)
										{
											n_bnum-=1;
										}
										
									}
								}
								int pos=TextCode.size();
								for(int i=n_bnum+1;i<=t_bnum;i++)
								{
									TextCode.add(pos,"b" + i + ":");
									TextCode.add(pos,"\n");
									TextCode.add(pos,"br label " + "\%" + "b" + i);
									pos=TextCode.size();
								}
								elsevalue=-1;
								ifvalue=0; 
								ifcnt=0;
								ifpMap.clear();
								ifcMap.clear();
								staArr.clear();
								conArr.clear();
							};

return_statements: RETURN a=arith_expression ';' {
																	//ret i32 0
																	if($a.theInfo.theType==Type.INT){
																		TextCode.add("ret i32" + $a.theInfo.theVar.iValue);
																	}
																	else if($a.theInfo.theType==Type.VOID){
																		TextCode.add("ret void");
																	}
																	else if($a.theInfo.theType==Type.LONG){
																		TextCode.add("ret i64" + $a.theInfo.theVar.iValue);
																	}
																	else if($a.theInfo.theType==Type.FLOAT){
																		TextCode.add("ret float" + $a.theInfo.theVar.fValue);
																	}
																	else if($a.theInfo.theType==Type.DOUBLE){
																		TextCode.add("ret double" + $a.theInfo.theVar.fValue);
																	}
																	} ;		  

scanf_statements: SCANF {if(scanfValue==0){scanfValue=1;TextCode.add(0,"declare dso_local i32 @scanf(i8*, ...)");}} '(' a=STRING {
			String tempa=($a.text);
			char[] tempb=new char[2*tempa.length()+2];
			int cnt=0;
			int templ=0;
			for(int i=0;i<tempa.length();i++)
			{ 
				if(i==tempa.indexOf("\\n",i))
				{
					tempb[cnt]='\\';
					tempb[cnt+1]='0';
					tempb[cnt+2]='A';
					cnt+=3;
					templ+=1;
					i+=1;
				}
				else if(i==tempa.length()-1)
				{
					tempb[cnt]='\\';
					tempb[cnt+1]='0';
					tempb[cnt+2]='0';
					tempb[cnt+3]='"';
					templ+=1;
					cnt+=4;
					
				}
				else
				{
					tempb[cnt]=tempa.charAt(i);
					if(i!=0)
					{
						templ+=1;
					}
					cnt+=1;
				}
			}
			printStr=String.valueOf(tempb);
			printStr=printStr.substring(0,cnt);
			TextCode.add(0,"@.str." + strCount + " = private unnamed_addr constant [" + templ + " x i8] c" + printStr + ", align 1");
			
		} (',' ('&'?) ID {arrvalue=0;} ('[' b=Integer_constant ']' {arrvalue=1;})? {

											Info ae=symtab.get($ID.text);
											String tempt="";
											int vIndex = ae.theVar.varIndex;
											int varc_switch=0;
											if(ae.theType==Type.INT)
											{
												tempt="i32";
												if(arrvalue==1)
												{
													int arrIndex=symtab.get($ID.text).theVar.arrSize;
													TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i32], [" + arrIndex + " x i32]* " + "\%" + "t" + vIndex + ", i64 0, i64 " + Integer.parseInt($b.text));
													varc_switch=1;
												}
											}
											else if(ae.theType==Type.LONG)
											{
												tempt="i64";
												if(arrvalue==1)
												{
													int arrIndex=symtab.get($ID.text).theVar.arrSize;
													TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x i64], [" + arrIndex + " x i64]* " + "\%" + "t" + vIndex + ", i64 0, i64 " + Integer.parseInt($b.text));
													varc_switch=1;
												}
											}
											else if(ae.theType==Type.FLOAT)
											{
												tempt="float";
												if(arrvalue==1)
												{
													int arrIndex=symtab.get($ID.text).theVar.arrSize;
													TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x float], [" + arrIndex + " x float]* " + "\%" + "t" + vIndex + ", i64 0, i64 " + Integer.parseInt($b.text));
													varc_switch=1;
												}
											}
											else if(ae.theType==Type.DOUBLE)
											{
												tempt="double";
												if(arrvalue==1)
												{
													int arrIndex=symtab.get($ID.text).theVar.arrSize;
													TextCode.add("\%" + "t" + varCount + " = getelementptr inbounds [" + arrIndex + " x double], [" + arrIndex + " x double]* " + "\%" + "t" + vIndex + ", i64 0, i64 " + Integer.parseInt($b.text));
													varc_switch=1;
												}
											}
											if(varc_switch==1)
											{
												printPara+=", " + tempt + "* " + "\%" + "t" +varCount;
												varCount+=1;
											}
											else
											{
												printPara+=", " + tempt + "* " + "\%" + "t" +vIndex;
											}
										})* ')' ';' {
										TextCode.add("\%" + "t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds ([" + templ + " x i8], [" + templ + " x i8]* @.str." + strCount + ", i64 0, i64 0)" + printPara + ")");
										printPara="";
										printStr="";
										strCount+=1;
										varCount+=1;
										};


/* description of the tokens */
INT  : 'int';
CHAR : 'char';
VOID : 'void';
FLOAT: 'float';
LONG : 'long';
DOUBLE:'double';
CONST: 'const';
UNSIGNED:'unsigned';
SIGNED:'signed';
DEFAULT  : 'default';
GOTO     : 'goto';
SIZEOF   : 'sizeof';
DO       : 'do';
IF       : 'if';
CONTINUE : 'continue';
FOR      : 'for';
RETURN   : 'return';
TYPEDEF  : 'typedef';
BREAK    : 'break';
ELSE     : 'else';
SWITCH   : 'switch';
CASE     : 'case';
WHILE    : 'while';
INCLUDE  : '#include';
DEFINE   : '#define';
SCANF    : 'scanf';

IO_INT : '\%d';
IO_FLOAT: '\%f';
IO_CHAR: '\%c';
IO_STR: '\%s';


MAIN:'main';
ARGC:INT 'argc';
ARGV:(CHAR MUL_CH MUL_CH 'argv')|(CHAR MUL_CH 'argv' LBRA_CH RBRA_CH );
PRINTF:'printf';
MALLOC:'malloc';
MEMSET:'memset';
STRCPY:'strcpy';
STRTOK:'strtok';
CALLOC:'calloc';
STRCAT:'strcat';
FREE:'free';
EXIT:'exit';
ATOI:'atoi';

EQ_OP : '==';
LE_OP : '<=';
GE_OP : '>=';
NE_OP : '!=';
PP_OP : '++';
MM_OP : '--';
RSHIFT_OP : '<<';
LSHIFT_OP : '>>';
AND_OP: '&&';
OR_OP : '||';


/*----------------------*/
/*  Special Characters  */
/*----------------------*/

COM_CH : ',';
PER_CH : '.';
/*SCOL_CH: ';';*/
COL_CH : ':';
QUE_CH : '?';
APO_CH : '\'';
DAPO_CH: '"';
EXC_CH : '!';
VER_CH : '|';
FSLA_CH: '/';
BSLA_CH: '\\';
TIL_CH : '~';
DOL_CH : '$';
MOD_CH : '%';
LCBRA_CH:'{';
RCBRA_CH:'}';
LBRA_CH: '[';
RBRA_CH: ']';
LPAR_CH: '(';
RPAR_CH: ')';
AMP_CH : '&';
CAR_CH : '^';
ADD_CH : '+';
SUB_CH : '-';
MUL_CH : '*';
GT_CH  : '>';
LT_CH  : '<';
HAS_CH : '#';
ASS_CH : '=';

ASSP_CH:'+=';
ASSMI_CH:'-=';
ASSMU_CH:'*=';
ASSD_CH:'/=';

ASCII:'!'..'~';


ID:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;

Floating_point_constant:'0'..'9'+ '.' '0'..'9'+;


WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};

/* Comments */
COMMENT1 : '//'(.)*'\n';
COMMENT2 : '/*' .* '*/' {$channel=HIDDEN;};

STRING: '"' (.)* '"';

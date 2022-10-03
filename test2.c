void main()
{
   int num1=100;
   int num2=200;
   num1+=num1|num2;
   num1-=num1^num2;
   num1*=num1&num2;
   num1 --;
   if(num1!=num2) {
        printf("num1 is not equal to the original num1\n");
   }
   else{
        printf("num1 is equal to the original num1\n");
   }
   printf("num1 is:%d\n",num1);
}

void main()
{
   double students[3] ;
   double avg=0.0;
   int cnt;
   printf("Please enter the scores of 3 students:\n");
   scanf("%lf%lf%lf",&students[0],&students[1],&students[2]);
   avg+=students[0];
   avg+=students[1];
   avg+=students[2];
   avg/=3;
   printf("average score is:%lf\n",avg);

}

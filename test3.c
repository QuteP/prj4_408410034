void main()
{
  int num;
  int result = 0;
  printf("Please enter an integer:");
  scanf("%d", &num);

  if (num > 100) {
    result = 30 * (num - 10);
  }
  else {
    result = num * num;
  }

  printf("The result is %d\n", result);
}


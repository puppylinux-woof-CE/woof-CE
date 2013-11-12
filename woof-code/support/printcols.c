/*(c) Copyright Barry Kauler 2009*/
/*Invoke like this: printcols afilename 1 6 2 9
  ...columns with '|' delimiter character get printed, in order specified.
     handles up to 15 columns, max line length 1023 characters.
Designed for use in the Puppy Package Manager, puppylinux.com
Compile statically:
# diet gcc -nostdinc printcols.c -o printcols
*/

#include <stdio.h>
#include <string.h>

int main (int argc, char ** argv) {
 int cntargs;
 char buffer1[2048];
 FILE* fp;
 char* ptoken1;
 char* ptoken2;
 char* ptoken3;
 char* ptoken4;
 char* ptoken5;
 char* ptoken6;
 char* ptoken7;
 char* ptoken8;
 char* ptoken9;
 char* ptoken10;
 char* ptoken11;
 char* ptoken12;
 char* ptoken13;
 char* ptoken14;
 char* ptoken15;
 int i;
 int cnt;
	int nextarg;
 
 fp = fopen(argv[1],"r");
 
 while( fgets(buffer1,2047,fp) != NULL ) {
  
  cnt=1;
  cntargs=2;

  ptoken1=&buffer1[0];

  for (i=0;i<2048;i=i+1) {
   if (buffer1[i]==0) break;
   if (buffer1[i]=='|') {
    cnt=cnt+1; buffer1[i]=0; 
	   if (cnt==2) ptoken2=&buffer1[i+1];
	   else if (cnt==3) ptoken3=&buffer1[i+1];
	   else if (cnt==4) ptoken4=&buffer1[i+1];
	   else if (cnt==5) ptoken5=&buffer1[i+1];
	   else if (cnt==6) ptoken6=&buffer1[i+1];
	   else if (cnt==7) ptoken7=&buffer1[i+1];
	   else if (cnt==8) ptoken8=&buffer1[i+1];
	   else if (cnt==9) ptoken9=&buffer1[i+1];
	   else if (cnt==10) ptoken10=&buffer1[i+1];
	   else if (cnt==11) ptoken11=&buffer1[i+1];
	   else if (cnt==12) ptoken12=&buffer1[i+1];
	   else if (cnt==13) ptoken13=&buffer1[i+1];
	   else if (cnt==14) ptoken14=&buffer1[i+1];
	   else if (cnt==15) ptoken15=&buffer1[i+1];
   }
  }
		
		/*print the fields in requested order...*/
		for (cntargs=2;cntargs<argc;cntargs++) {
			
			nextarg=atoi(argv[cntargs]);
			
			if ( nextarg >= cnt ) { printf("|"); continue; } /*in case of lines with less fields*/
			if (nextarg==1) printf("%s|",ptoken1);
			else if (nextarg==2) printf("%s|",ptoken2);
			else if (nextarg==3) printf("%s|",ptoken3);
			else if (nextarg==4) printf("%s|",ptoken4);
			else if (nextarg==5) printf("%s|",ptoken5);
			else if (nextarg==6) printf("%s|",ptoken6);
			else if (nextarg==7) printf("%s|",ptoken7);
			else if (nextarg==8) printf("%s|",ptoken8);
			else if (nextarg==9) printf("%s|",ptoken9);
			else if (nextarg==10) printf("%s|",ptoken10);
			else if (nextarg==11) printf("%s|",ptoken11);
			else if (nextarg==12) printf("%s|",ptoken12);
			else if (nextarg==13) printf("%s|",ptoken13);
			else if (nextarg==14) printf("%s|",ptoken14);
			else if (nextarg==15) printf("%s|",ptoken15);
	 }
		printf("\n");
 }

 
 fclose(fp);

 return 0;
}


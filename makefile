 main1: main1.o sub1.o
	gcc -o main1 main1.o sub1.o
main1.o:main1.c sub1.h
	gcc -c main1.c
sub1.o:sub1.c sub1.h
	gcc -c sub1.c
clean:
	rm *.o main1


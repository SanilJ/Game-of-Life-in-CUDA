#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <cuda.h>

extern "C"
{
#include "png_util.h"
}

// to compile

// to convert output png files to an mp4 movie:
// ffmpeg -y -start_number 0 -r 24 -i gol%05d.png -b:v 8192k -c:v mpeg4 gol.mp4

/* function to convert from (i,j) cell index to linear storage index */
int idx(int N, int i, int j){
  int n = i + (N + 2)*j;
  return n;  
}

/* function to update Inew from Iold */
__global__ void cudaIterate(int N, float *Iold, float *Inew){
  int t = threadIdx.x;
  int b = blockIdx.x;
  int d = blockDim.x;

  int n = d*b +t;
  if(n<N+1&& n>0){
    int len = N+2;
    int surroundings = Iold[n-1] + Iold[n+1] + Iold[n+len] + Iold[n+len-1] +
      Iold[n+len+1] + Iold[n-len-1] + Iold[n-len] + Iold[n-len+1];
    int oldState = Iold[n];
    int newState = (oldState==1)?((surroundings==2)||(surroundings==3)):(surroundings==3);
    Inew[n] = newState;
  }
}

/* function to print game board for debugging */
void print_board(int N, float *board){
  printf("\n");
  for(int i=1; i<N+1; i=i+1){
    for(int j=1; j<N+1; j=j+1){
      printf("%d", (int)board[idx(N,i,j)]);
    }
    printf("\n");
  }
  printf("\n");
}

/* function to solve for game board using Game of Life rules */
void solve(int N){

  
  /* Intializes integer random number generator */
  //  srand((unsigned) time(&t));
  srand(123456);

  // notice the size of these arrays
  float* h_Inew = (float*) calloc((N+2)*(N+2),sizeof(float));
  float* h_Iold = (float*) calloc((N+2)*(N+2),sizeof(float));
  float *c_Inew, *c_Iold;
  cudaMalloc(&c_Inew, (N+2)*(N+2)*sizeof(float));
  cudaMalloc(&c_Iold, (N+2)*(N+2)*sizeof(float));
  
  for(int i=1;i<N+1;i=i+1){
    for(int j=1;j<N+1;j=j+1){
      // set board state randomly to 1 or 0 
      h_Iold[idx(N,i,j)] = rand()%2;
    ls}
  }
  /* print initial board*/
  //printf("initial game board:");
  //print_board(N, h_Iold);

  cudaMemcpy(c_Iold, h_Iold, (N+2)*(N+2)*sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(c_Inew, h_Inew, (N+2)*(N+2)*sizeof(float), cudaMemcpyHostToDevice);
  /* iterate here */
  int B = 256;
  int G = (N+B-1)/B;
  int count = 0;   // step counter
  int iostep = 10; // output every iostep
  int output = 1;  // save images if output=1
  int maxsteps = 1000; // maximum number of steps
  do{
    /* iterate from Iold to Inew */
    cudaIterate<<<G, B>>>(N, c_Iold, c_Inew);
    
    /* iterate from Inew to Iold */
    cudaIterate<<<G, B>>>(N, c_Inew, c_Iold);
    cudaMemcpy(h_Iold, c_Iold, (N+2)*(N+2) * sizeof(float), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_Inew, c_Inew, (N+2)*(N+2) * sizeof(float), cudaMemcpyDeviceToHost);
    if(output==1 && count%iostep==0){
      char filename[BUFSIZ];
      FILE *png;
      sprintf(filename, "gol%05d.png", count/iostep);
      png = fopen(filename, "w");
      write_gray_png(png, N+2, N+2, h_Iold, 0, 1);
      fclose(png);
    }
    
    /* update counter */
    count = count + 1;
  }while(memcmp(h_Inew, h_Iold, (N+2)*(N+2)*sizeof(int))!=0 && count <= maxsteps);
  
  /* print out the cell existence in the whole board, then in cell (1 1) and (10 10)*/
  //printf("final game board:");
  // print_board(N, h_Iold);
  printf("I_{1 1} = %d\n",   (int)h_Iold[idx(N,1,1)]);
  printf("I_{10 10} = %d\n", (int)h_Iold[idx(N,10,10)]);
  printf("Took %d steps\n", count);
  free(h_Inew);
  free(h_Iold);
}



/* usage: ./main 100 
         to iterate, solve and display the game board of size N*/
int main(int argc, char **argv){

  if(argc!=2){
    printf("To run with an (N+2)x(N+2) board: \n");
    printf("  ./gameOfLife N\n");
    exit(-1);
  }
  
  /* start timer */
  clock_t begin = clock();
  /* read N from the command line arguments */
  int N = atoi(argv[1]);

  /* to solve for cell existence in game of life game board */
  solve(N);

  /* end timer*/
  clock_t end = clock();
  double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
  printf("Time spent = %g sec\n", time_spent);
  return 0;
}

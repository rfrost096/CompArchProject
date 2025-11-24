#include "hpm.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define SIZE 32

void multiplication(int** mat_A, int** mat_B, int** mat_product, int N)
{
    int i, j, k;
    //Matrix multiplication without transposing the B matrix
    for (i = 0; i < N; i++) {
        for (j = 0; j < N; j++) {
            for (k = 0; k < N; k++)
		        mat_product[i][j] += mat_A[i][k] * mat_B[k][j];
        }
    }
}

int main(void)
{
    printf("Generating matrices of size %d * %d \n",SIZE,SIZE);

    int **mat_A = (int **)malloc(SIZE * sizeof(int *)); 
    int **mat_B = (int **)malloc(SIZE * sizeof(int *));
    int **mat_product = (int **)malloc(SIZE * sizeof(int *));
  
    for (int i=0; i<SIZE; i++) { 
        mat_A[i] = (int *)malloc(SIZE * sizeof(int)); 
	    mat_B[i] = (int *)malloc(SIZE * sizeof(int));
	    mat_product[i] = (int *)malloc(SIZE * sizeof(int));
    }

    for( int i=0; i<SIZE; i++) {
        for(int j=0; j<SIZE; j++) {
            mat_A[i][j]= i-j;
            mat_B[i][j]= 1;
            mat_product[i][j] = 0;
        }
    }
    printf("Computing the product....\n");

    /* Enable performance counters */
    hpm_init();

    // Matrix multiplication with B
    multiplication(mat_A, mat_B, mat_product, SIZE);

    /* Print performance counter data */
    hpm_print();

    return 0;
}

#include<stdio.h>
#include<stdlib.h>
#include <sys/time.h>
#include<omp.h>

#define C0 0.5
#define C1 0.75
#define INICIO 1
#define FIM 2

int write_output(float *, int, int);
float get_time(int);

struct timeval inicio, final;

int main(int argc, char* argv[]){

 int niter,dim,save,ret;
 int t,i,j,k,t0,t1;
 float *heat_, tf_sec;

 if(argc < 4){
        printf("Error! informe o número de iterações e o tamanho da matriz. i.e: ./executavel 1000 500 500\n");
	exit(1);
 }
 niter = atoi(argv[1]);
 dim = atoi(argv[2]);
 save = atoi(argv[3]);
 
 #ifdef VERBOSE
 printf("Número de iterações %d\ndimensão %d salvo a cada %d timesteps\n",niter,dim,save);
 #endif

 heat_ = (float*) malloc(sizeof(float)*2*dim*dim*dim);

 if(heat_ == NULL){
        printf("Error! Malloc fail\n");
        exit(1);
 }

 float (*heat)[dim][dim][dim] = (float (*)[dim][dim][dim]) heat_;
 ret = system("/usr/bin/power_gov -r POWER_LIMIT -s 23 -d PP0 -p 1");
 #ifdef VERBOSE
 printf("Retornou código %d ao setar limite!\n",ret);
 printf("Inicializando matriz!\n");
 #endif

#pragma omp parallel for
 for(i=0;i<dim;i++){
   for(j=0;j<dim;j++){
     for(k=0;k<dim;k++){
	heat[1][i][j][k] = heat[0][i][j][k] = 1;
     }
   }
 }

 #ifdef VERBOSE
 printf("Iniciando computação do stencil!\n");
 #endif

 get_time(INICIO);
 for(t=1; t<niter+1; t++){
        t0 = (t % 2);
        t1 = (t0 + 1)%(2);
	
	#pragma omp parallel for
        for(i=1;i<dim-1;i++){
          for(j=1;j<dim-1;j++){
            for(k=1;k<dim-1;k++){
                heat[t0][i][j][k] = C0 * heat[t1][i][j][k] + C1 * (heat[t1][i+1][j][k] + heat[t1][i-1][j][k] + heat[t1][i][j+1][k] + heat[t1][i][j-1][k] + heat[t1][i][j][k+1] + heat[t1][i][j][k-1]);
            }
          }
        }
	if((t % save) == 0) write_output(heat_, dim, t0);	
 }
 tf_sec = get_time(FIM);
 printf("Time elapsed: %.3f seg\n",tf_sec);


 free(heat_);

 return 0;
}
 
float get_time(int mode){
 
 float tf_sec = 0.0;

 if(mode == INICIO){
 	gettimeofday(&inicio, NULL);
 }
 else{
 	gettimeofday(&final, NULL);
 	unsigned long long seg = 1000 * (final.tv_sec - inicio.tv_sec) + (final.tv_usec - inicio.tv_usec) / 1000;
 	tf_sec = ((float)seg)*1e-3;
 }
 return tf_sec;
}

int write_output(float *heat_, int dim, int timestep){
 
 FILE *fff;
 int i,j,k,ret;
 float (*heat)[dim][dim][dim] = (float (*)[dim][dim][dim]) heat_;
 
 ret = system("/usr/bin/power_gov -r POWER_LIMIT -s 11 -d PP0 -p 1");
 #ifdef VERBOSE
 printf("Retornou código %d ao setar limite!\n",ret);
 #endif
 fff = fopen("output.txt","w");
 if (fff==NULL){
   printf("Error! Não foi possível abrir o arquivo para saída.\n");
   return 1;
 }

 for(i=0;i<dim;i++){
   for(j=0;j<dim;j++){
     for(k=0;k<dim;k++){
	fprintf(fff,"%f ",heat[timestep][i][j][k]);
     }
   }
 }
 fclose(fff);
 ret = system("/usr/bin/power_gov -r POWER_LIMIT -s 23 -d PP0 -p 1");
 #ifdef VERBOSE
 printf("Retornou código %d ao setar limite!\n",ret);
 #endif
 return 0;
}

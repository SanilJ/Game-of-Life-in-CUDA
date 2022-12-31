gameOfLife: gameOfLifeCudaShared.cu
	nvcc -I. -O3 -o cudaGameOfLifeShared gameOfLifeCudaShared.cu png_util.c -lpng -lm 

clean:
	rm cudaGameOfLifeShared gol*png

run:
	./cudaGameOfLifeShared 2048


movie:
	@echo WARNING YOU MUST BE LOGGED INTO THE HEAD NODE TO RUN THIS
	ffmpeg -y -start_number 0 -r 24 -i gol%05d.png -b:v 8192k -c:v mpeg4 gol.mp4

test4:test1.cpp
	g++ test1.cpp -o test4 `pkg-config --cflags --libs opencv`
CC      = gcc
CPP     = g++
RM      = rm -f

#支持debug 
## debug flag  
DBG_ENABLE := 1

# #检查当前系统 
# OS = $(shell uname)

#输出目标路径及名称
## target file name  
TARGET_LIB:=../api/lib/libKeySafeLinger.so
TARGET := run

# linux环境下操作特大文件
## macro define
DEFS := __LINUX__ OS_LINUX _FILE_OFFSET_BITS=64


#--------------------------------SDK外-依赖--------------------------------
#opencv
LIBOPENCV_INC = $(shell pkg-config --cflags opencv)
LIBOPENCV_LIBS = $(shell pkg-config --libs opencv)

# #cuda     
LIBCUDA_INC = /usr/local/cuda/include/ /usr/local/cuda/targets/x86_64-linux/lib/
# LIBCUDA_LIBPATH = /usr/local/cuda/lib64/        #cuda安装在系统路径下，库的路径可以不填，注释

#cudnn
LIBCUDNN_INC = /usr/local/cuda/include/         #cudnn头文件在cuda include路径下，cuda已经引用过该路径，可以注释
# LIBCUDNN_LIBPATH = /usr/lib/x86_64-linux-gnu/   #系统路径，注释

#libtorch
LIBTORCH_INC = /home/h/libtorch/include/  /home/h/libtorch/include/torch/csrc/api/include/
LIBTORCH_LIBPATH = /home/h/libtorch/lib/

#tensorRT
LIBTENSORRT_INC = /home/h/Downloads/TensorRT-7.2.2.3/include/
LIBTENSORRT_LIBPATH = /home/h/Downloads/TensorRT-7.2.2.3/lib/

#eigen
LIBEIGEN_INC = /usr/include/eigen3/


#汇总
#头文件路径 +库名称 +库路径
INCLUDE_PATH += $(LIBOPENCV_INC) $(LIBCUDA_INC) $(LIBCUDNN_INC) $(LIBTORCH_INC) $(LIBTENSORRT_INC) $(LIBEIGEN_INC)
LIBS +=$(LIBOPENCV_LIBS) -lcuda -lcudart -lc10 -lc10_cuda  -ltorch -ltorch_cpu -ltorch_cuda -lshm -lnvinfer -lnvinfer_plugin  -ldecodeplugin -lnvonnxparser -lyaml-cpp -luuid
LIBRARY_PATH += $(LIBTORCH_LIBPATH) $(LIBTENSORRT_LIBPATH)  
#LIBRARY_PATH +=  $(LIBCUDA_LIBPATH) $(LIBCUDNN_LIBPATH) $(LIBTORCH_LIBPATH) $(LIBTENSORRT_LIBPATH)  



#------------------------------SDK内-资源-------------------------------
#头文件路径 +库名称 +库路径
INCLUDE_PATH += ../detector/ ../common/ ../tracker/sort/ ../tracker/featureExtractor/ ../judge/ ../api/include/ ../facedetect/include/
LIBS += -lyolov5_trt   -lboost_system  -lboost_thread
LIBRARY_PATH += ../facedetect/lib/ ../detector/

#源文件路径
SRC_PATH :=../api/src/ ../common/ ../detector/ ../tracker/sort/ ../tracker/featureExtractor/ ../judge/  

#获取全部.c和.cpp源文件
SRCS := $(foreach spath, $(SRC_PATH), $(wildcard $(spath)*.c*) )

#全部源文件编译成.o文件
## all .o based on all .c/.cpp
OBJS = $(SRCS:.c=.o)
OBJS := $(OBJS:.cpp=.o) 


 
#是否要用gdb来debug 
## debug for debug info, when use gdb to debug  
ifeq (1, ${DBG_ENABLE})   
CFLAGS += -D_DEBUG -g -DDEBUG=1 
else
CFLAGS += -O3 -DNDEBUG
endif


CFLAGS += -fPIC $(foreach m, $(DEFS), -D$(m)) 
  
#所有头文件路径 -I
CFLAGS  += $(foreach dir, $(INCLUDE_PATH), -I$(dir))  
CXXFLAGS += -std=c++14 $(CFLAGS) -std=c++14

#所有库路径-L  + 所有库名称-l
LDFLAGS += -Wl,--no-as-needed -lpthread $(foreach lib, $(LIBRARY_PATH), -L$(lib))   #-Wl,--no-as-needed命令必须要有，否则无法使用gpu
LDFLAGS += $(LIBS)  -Wl,--rpath=../facedetect/lib/ -Wl,--rpath=../detector/  -Wl,--rpath=/home/h/libtorch/lib/  


default: all

%.o: %.c
	$(CC) $(CFLAGS) -std=c99 -c $< -o $@

%.o: %.cpp
	$(CPP) $(CXXFLAGS) -c $< -o $@
	
all: $(OBJS)  
	$(CPP) $(CXXFLAGS) -shared -o $(TARGET_LIB) $(OBJS)  $(LDFLAGS)  
	$(CPP) -std=c++14 -g -fPIC -I../api/include/ -I../tracker/featureExtractor/ -I$(LIBTENSORRT_INC) ../main.cpp  -o $(TARGET) -L../api/lib/  -lKeySafeLinger

clean:  
	$(RM) $(OBJS) $(TARGET) $(TARGET_LIB) 


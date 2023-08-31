#include <iostream>
#include <fstream>
#include <stdint.h>
#include <string.h>
#include <mex.h>

using namespace std;

typedef uint32_t OmSegID;

struct OmColor {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
};

struct OmSegmentDataV4 {
    OmSegID value;
    OmColor color;
    uint64_t size;
    //AxisAlignedBoundingBox<int> bounds;	// 26 bytes
    char padding[26];
};

extern "C" void mexFunction(int nlhs, mxArray *plhs[],
      int nrhs, const mxArray *prhs[]);

void mexFunction(int nlhs, mxArray *plhs[],
      int nrhs, const mxArray *prhs[])
{
	const char* metadataPath = mxArrayToString(prhs[0]);
	ifstream metadata( metadataPath, ios::binary | ios::ate );

	if( metadata )
	{
		int fileSize = metadata.tellg();
		char buf[fileSize];
		metadata.seekg(0,ios::beg);
		metadata.read(buf,sizeof(buf));	
		metadata.close();

		OmSegmentDataV4* data = reinterpret_cast<OmSegmentDataV4*>(buf);
		
		int nData = fileSize/sizeof(OmSegmentDataV4);
		//OmSegID segID[nData] = {0,};
		//uint64_t size[nData] = {0,};
		OmSegID segID[nData];
		uint64_t size[nData];
		memset(segID,0,nData*sizeof(OmSegID));
		memset(size,0,nData*sizeof(uint64_t));
		for( int i = 0; i < nData; ++i )
		{
			segID[i] = data[i].value;
			size[i]  = data[i].size;
		}		

		int ndim = 2;
		int dims[2] = {1,nData};
		
		plhs[0] = mxCreateNumericArray(ndim,dims,mxUINT32_CLASS,mxREAL);
		plhs[1] = mxCreateNumericArray(ndim,dims,mxUINT64_CLASS,mxREAL);
		
		unsigned char* start_of_pr;		
		size_t bytes_to_copy;

		start_of_pr = (unsigned char*)mxGetData(plhs[0]);
		bytes_to_copy = nData*mxGetElementSize(plhs[0]);
		memcpy(start_of_pr,segID,bytes_to_copy);
		
		start_of_pr = (unsigned char*)mxGetData(plhs[1]);
		bytes_to_copy = nData*mxGetElementSize(plhs[1]);
		memcpy(start_of_pr,size,bytes_to_copy);
	}
}
#include "mex.h"
#include<iostream>
#include <algorithm>
#include <cmath>
#include "math.h"
#include <stdlib.h>
#include <float.h>
#include "matrix.h"
#include<stdio.h>
#include <string.h>

#include <unordered_map>  
#include <iostream>  

using namespace std;

static int pnt2ind(int px, int py, int pz);
static int* ind2pnt(int ind);
static double penalty(int ind);
static int* get_conn_list(int ind);
static bool ismember(int a, int *que, int length);
static double calc_dist(int ind1, int ind2);

static long unsigned int x_vol_size[3] = {0,0,0};
static double *x_dbf;
static double max_dbf = 0;
static int num_conn = 0;

static int ncheck = 0;
static int dopenal = 1;

typedef std::unordered_map<int, int> Queue;

void mexFunction(int ds, mxArray *d[], int ss, const mxArray *s[])
{   
    double *x2, *x3, *x4;
    
    x_dbf = mxGetPr(s[0]);
    x2 = mxGetPr(s[1]);
    x3 = mxGetPr(s[2]);
    x4 = mxGetPr(s[3]);
    dopenal = (int) x4[0];
    
    int x_rt_pnt[3] = {0,0,0};
    
    for(int i=0; i<mxGetN(s[1]); i++)
        x_vol_size[i] = (const long unsigned int) x2[i];
    
    for(int i=0; i<mxGetN(s[2]); i++)
        x_rt_pnt[i] = (int) x3[i];
    
    //mexPrintf("volume_size = %d,%d,%d\n", x_vol_size[0],x_vol_size[1],x_vol_size[2]);
    //mexPrintf("root point = %d,%d,%d\n", x_rt_pnt[0],x_rt_pnt[1],x_rt_pnt[2]);
    
    d[0] = mxCreateNumericArray(3, x_vol_size, mxDOUBLE_CLASS,mxREAL);
    d[1] = mxCreateNumericArray(3, x_vol_size, mxDOUBLE_CLASS,mxREAL);
    d[2] = mxCreateNumericArray(3, x_vol_size, mxDOUBLE_CLASS,mxREAL);

    double *y_pdrf, *y_ind_from, *y_surf;
    
    int asize = x_vol_size[0]*x_vol_size[1]*x_vol_size[2];
    //int *labled_procd = (int*) mxMalloc(sizeof(int)*asize);
            
    y_pdrf = mxGetPr(d[0]);
    y_ind_from = mxGetPr(d[1]);
    y_surf = mxGetPr(d[2]);
    
    //initialization
    for(int i=0;i<asize;i++)
    {
        y_pdrf[i] = DBL_MAX;
        y_ind_from[i] = -1;
        //labled_procd[i] = 0;
        y_surf[i] = 0;
    }
    
    int rt_ind = pnt2ind(x_rt_pnt[0], x_rt_pnt[1], x_rt_pnt[2]);
    //mexPrintf("root ind = %d\n", rt_ind);
    
    int num_traced_vox = 0;
    for(int i=0;i<asize;i++)
    {
        if(x_dbf[i]!=0)
        {
            num_traced_vox++;
            if(x_dbf[i]>max_dbf)
                max_dbf = x_dbf[i];
        }
    }
    
    //mexPrintf("ddst = %d\n", num_traced_vox);
    
    num_traced_vox = num_traced_vox;
    
    Queue q1;
    Queue q2;
    Queue lp;
    
    q1.insert(Queue::value_type(rt_ind, 0));
    
    y_pdrf[rt_ind-1] = penalty(rt_ind);
    
    int *conn = new int[27];
    int n=0; int p=0;
    while( (q1.size()>0 || q2.size()>0)  && n<num_traced_vox )
    {   
        for (Queue::iterator iti = q1.begin(); iti != q1.end(); ++iti)
        {
            int que1i = iti->first;
            double dist_prev = y_pdrf[ que1i-1 ];
            conn = get_conn_list(que1i);
            
            p=0;
            for(int j=0; j<num_conn;j++)
            {
                int connj = conn[j];
                if(x_dbf[ connj-1 ]==0)
                {
                    p=1;
                    continue;
                }
                
                if(    (q1.find(connj) == q1.end()) 
                    && (q2.find(connj) == q2.end())
                    && (lp.find(connj) == lp.end()))
                {
                    q2.insert(Queue::value_type(connj,0));
                }
                
                double dist_now = dist_prev + calc_dist(que1i,connj)*penalty(connj);
                if(dist_now < y_pdrf[connj-1])
                {
                    y_pdrf[connj-1] = dist_now;
                    y_ind_from[connj-1] = que1i;
                }
            }
            //labled_procd[que1i-1] = 1;
	    lp.insert(Queue::value_type(que1i,1));
            if(p==1)
                y_surf[que1i-1] = 1;
        }
        
        //mexPrintf("%d\n", que1_length);
        
        q1=q2;
        q2.clear();
        
        n++;
        if(n>num_traced_vox-1)
            mexPrintf("Iterations exceed all traced voxels number\n");
    }
    y_ind_from[rt_ind-1] = 0;
    
    
    //mexPrintf("%d\n",ncheck);
    //mxFree(labled_procd);
    q1.clear();
    q2.clear();
    lp.clear();
    
    return;
}

static bool ismember(int a, int *que, int length)
{   
    int n=0;
    bool flag = false;
    while(n<length && flag==false)
    {
        if(a==que[n])
        {
            flag = true;
        }
        n++;
    }
    return flag;
}

static int pnt2ind(int px, int py, int pz)
{
    
    int ind = (pz-1)*x_vol_size[0]*x_vol_size[1] + (py-1)*x_vol_size[0] + px;
    return ind;
}

static int* ind2pnt(int ind)
{
    int *pnt = new int[3];
    
    pnt[2] = ind/(x_vol_size[0]*x_vol_size[1])+1;
    pnt[1] = (ind%(x_vol_size[0]*x_vol_size[1]))/x_vol_size[0]+1;
    pnt[0] = (ind%(x_vol_size[0]*x_vol_size[1]))%x_vol_size[0];
    
    return pnt;
}

static double calc_dist(int ind1, int ind2)
{
    ncheck++;
    
    int *pnt1 = new int[3]; pnt1 = ind2pnt(ind1);
    int *pnt2 = new int[3]; pnt2 = ind2pnt(ind2);
    
    double x1 = (double) pnt1[0];
    double x2 = (double) pnt2[0];
    double y1 = (double) pnt1[1];
    double y2 = (double) pnt2[1];
    double z1 = (double) pnt1[2];
    double z2 = (double) pnt2[2];
    
    double dist = sqrt( (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) + (z2-z1)*(z2-z1) );
    
    //double dist = 1;
    return dist;
}

static double penalty(int ind)
{

    double pnlt = 1;
    if(dopenal==0)
    {
	//mexPrintf("%d\n", dopenal);
        return pnlt;
    }
    double M = max_dbf + 1;
    //double pnlt = 5000*pow(1 - x_dbf[ind]/M,16);
    double c1 = 1 - x_dbf[ind-1]/M;
    //double pnlt = 5000*c1*c1*c1*c1*c1*c1*c1*c1*c1*c1*c1*c1*c1*c1*c1*c1;
    pnlt = 5000*pow(c1, 32);
    
    return pnlt;
}

static int* get_conn_list(int ind)
{
    int *pnt = new int[3]; 
    pnt = ind2pnt(ind);

    int *conn = new int[27];
    
    int n=0;
    for(int z=-1;z<2;z++)
    {
        for(int y=-1;y<2;y++)
        {
            for(int x=-1;x<2;x++)
            {
                int xx = pnt[0]+x; 
                int yy = pnt[1]+y; 
                int zz = pnt[2]+z;
                
                if(x==0 && y==0 && z==0)
                    continue;
                else if(xx>x_vol_size[0] || yy>x_vol_size[1] || 
                        zz>x_vol_size[2] || xx<1 || yy<1 || zz<1)
                    continue;
                //else if (x_dbf[ pnt2ind(xx,yy,zz)-1 ]==0 )
                //    continue;
                
                int indind = pnt2ind(xx,yy,zz);
                conn[n] = indind;
                n=n+1;
            }
        }
    }
    
    num_conn = n;
    return conn;
}
 























































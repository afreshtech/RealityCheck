/*==============================================================================
            Copyright (c) 2012-2013 QUALCOMM Austria Research Center GmbH.
            All Rights Reserved.
            Qualcomm Confidential and Proprietary
            
@file 
    Quad.h

@brief
    Geometry for a quad used in the samples.

==============================================================================*/

#ifndef _QCAR_QUAD_H_
#define _QCAR_QUAD_H_


#define NUM_QUAD_VERTEX 4
#define NUM_QUAD_INDEX 6


static const float quadVertices[NUM_QUAD_VERTEX * 3] =
{
   -1.00f,  -1.00f,  -1.00f, 
    1.00f,  -1.00f,  -1.00f,
    1.00f,   1.00f,  -1.00f,
   -1.00f,   1.00f,  -1.00f,
};

static const float quadTexCoords[NUM_QUAD_VERTEX * 2] =
{
    0, 0,
    1, 0,
    1, 1,
    0, 1,
};

static const float quadNormals[NUM_QUAD_VERTEX * 3] =
{
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,

};

static const unsigned short quadIndices[NUM_QUAD_INDEX] =
{
     0,  1,  2,  0,  2,  3, // front
};


#endif // _QC_AR_QUAD_H_

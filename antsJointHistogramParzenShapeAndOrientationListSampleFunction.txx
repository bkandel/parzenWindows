/*=========================================================================

  Program:   Advanced Normalization Tools
  Module:    $RCSfile: antsJointHistogramParzenShapeAndOrientationListSampleFunction.txx,v $
  Language:  C++
  Date:      $Date: $
  Version:   $Revision: $

  Copyright (c) ConsortiumOfANTS. All rights reserved.
  See accompanying COPYING.txt or
  http://sourceforge.net/projects/advants/files/ANTS/ANTSCopyright.txt
  for details.

  This software is distributed WITHOUT ANY WARRANTY; without even
  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE.  See the above copyright notices for more information.

=========================================================================*/
#ifndef __antsJointHistogramParzenShapeAndOrientationListSampleFunction_txx
#define __antsJointHistogramParzenShapeAndOrientationListSampleFunction_txx

#include "antsJointHistogramParzenShapeAndOrientationListSampleFunction.h"

#include "itkArray.h"
#include "itkBSplineInterpolateImageFunction.h"
#include "itkContinuousIndex.h"
#include "itkDecomposeTensorFunction.h"
#include "itkDiscreteGaussianImageFilter.h"
#include "itkDivideByConstantImageFilter.h"
#include "itkStatisticsImageFilter.h"
#include "itkImageFileReader.h"
#include "itkImageFileWriter.h"
#include <sstream>

namespace itk {
namespace ants {
namespace Statistics {

template <class TListSample, class TOutput, class TCoordRep>
JointHistogramParzenShapeAndOrientationListSampleFunction<TListSample, TOutput, TCoordRep>
::JointHistogramParzenShapeAndOrientationListSampleFunction()
{
  this->m_NumberOfJointHistogramBins = 32;
  this->m_Sigma = 1.0;
  this->m_UseNearestNeighborIncrements = false;
  this->m_MaximumEigenvalue1 = 1.2;
  this->m_MaximumEigenvalue2 = 1.2;
  this->m_MinimumEigenvalue1 = 0.1;
  this->m_MinimumEigenvalue2 = 0.1;

  this->m_JointHistogramImages[0] = NULL;
  this->m_JointHistogramImages[1] = NULL;
  this->m_JointHistogramImages[2] = NULL;
  
}

template <class TListSample, class TOutput, class TCoordRep>
JointHistogramParzenShapeAndOrientationListSampleFunction<TListSample, TOutput, TCoordRep>
::~JointHistogramParzenShapeAndOrientationListSampleFunction()
{


}


template <class TListSample, class TOutput, class TCoordRep>
void
JointHistogramParzenShapeAndOrientationListSampleFunction<TListSample, TOutput, TCoordRep>
::IncrementJointHistogramForShape( RealType eigenvalue1, RealType eigenvalue2 )
{
  RealType newWeight = 1.0;

  // now define two joint histograms, one for shape, one for orientation.
  // first, the shape histogram --- 0,0 origin and spacing of 1
  if( !this->m_JointHistogramImages[0] )
    {
    this->m_JointHistogramImages[0] = JointHistogramImageType::New();
    typename JointHistogramImageType::SpacingType spacing;
    spacing.Fill( 1 );
    typename JointHistogramImageType::PointType origin;
    origin.Fill( 0 );
    typename JointHistogramImageType::SizeType size;
    size.Fill( this->m_NumberOfJointHistogramBins );
    this->m_JointHistogramImages[0]->SetOrigin( origin );
    this->m_JointHistogramImages[0]->SetSpacing( spacing );
    this->m_JointHistogramImages[0]->SetRegions( size );
    this->m_JointHistogramImages[0]->Allocate();
    this->m_JointHistogramImages[0]->FillBuffer( 0 );
    }

  typename JointHistogramImageType::PointType shapePoint;
  if( eigenvalue1 > 1.0 )
    {
    eigenvalue1 = 1.0;
    }
  if( eigenvalue2 > 1.0 )
    {
    eigenvalue2 = 1.0;
    }
  if( eigenvalue1 < 0.0 )
    {
    eigenvalue1 = 0.0;
    }
  if( eigenvalue2 < 0 )
    {
    eigenvalue2 = 0.0;
    }

  shapePoint[0] = eigenvalue1 * ( this->m_NumberOfJointHistogramBins - 1 );
  shapePoint[1] = eigenvalue2 * ( this->m_NumberOfJointHistogramBins - 1 );

  ContinuousIndex<double, 2> shapeCidx;
  this->m_JointHistogramImages[0]->TransformPhysicalPointToContinuousIndex(
    shapePoint, shapeCidx );

  typename JointHistogramImageType::IndexType shapeIdx;

  /** Nearest neighbor increment to JH */
  if( this->m_UseNearestNeighborIncrements )
    {
    shapeIdx[0] = vcl_floor( shapeCidx[0] + 0.5);
    shapeIdx[1] = vcl_floor( shapeCidx[1] + 0.5 );
    if( this->m_JointHistogramImages[0]->
      GetLargestPossibleRegion().IsInside( shapeIdx ) )
      {
      RealType oldWeight = this->m_JointHistogramImages[0]->GetPixel( shapeIdx );
      this->m_JointHistogramImages[0]->SetPixel( shapeIdx, 1 + oldWeight );
      }
    }
  else
    {
    /** linear addition */
    shapeIdx[0] = static_cast<IndexValueType>( vcl_floor( shapeCidx[0] ) );
    shapeIdx[1] = static_cast<IndexValueType>( vcl_floor( shapeCidx[1] ) );
    RealType distance1 = vcl_sqrt( vnl_math_sqr( shapeCidx[0] - shapeIdx[0] ) +
      vnl_math_sqr( shapeCidx[1] - shapeIdx[1] ) );
    shapeIdx[0]++;
    RealType distance2 = vcl_sqrt( vnl_math_sqr( shapeCidx[0] - shapeIdx[0] ) +
      vnl_math_sqr( shapeCidx[1] - shapeIdx[1] ) );
    shapeIdx[1]++;
    RealType distance3 = vcl_sqrt( vnl_math_sqr( shapeCidx[0] - shapeIdx[0] ) +
      vnl_math_sqr( shapeCidx[1] - shapeIdx[1] ) );
    shapeIdx[0]--;
    RealType distance4 = vcl_sqrt( vnl_math_sqr( shapeCidx[0] - shapeIdx[0] ) +
      vnl_math_sqr( shapeCidx[1] - shapeIdx[1] ) );
    RealType sumDistance = distance1 + distance2 + distance3 + distance4;
    distance1 /= sumDistance;
    distance2 /= sumDistance;
    distance3 /= sumDistance;
    distance4 /= sumDistance;

    unsigned int whichHistogram = 0;
    shapeIdx[0] = static_cast<IndexValueType>( vcl_floor( shapeCidx[0] ) );
    shapeIdx[1] = static_cast<IndexValueType>( vcl_floor( shapeCidx[1] ) );
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( shapeIdx ) )
      {
      RealType oldWeight =
        this->m_JointHistogramImages[whichHistogram]->GetPixel( shapeIdx );
      this->m_JointHistogramImages[whichHistogram]->SetPixel( shapeIdx,
        ( 1.0 - distance1 ) * newWeight + oldWeight );
      }
    shapeIdx[0]++;
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( shapeIdx ) )
      {
      RealType oldWeight =
        this->m_JointHistogramImages[whichHistogram]->GetPixel( shapeIdx );
      this->m_JointHistogramImages[whichHistogram]->SetPixel( shapeIdx,
        ( 1.0 - distance2 ) * newWeight + oldWeight );
      }
    shapeIdx[1]++;
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( shapeIdx ) )
      {
      RealType oldWeight
        = this->m_JointHistogramImages[whichHistogram]->GetPixel( shapeIdx );
      this->m_JointHistogramImages[whichHistogram]->SetPixel( shapeIdx,
        ( 1.0 - distance3 ) * newWeight + oldWeight );
      }
    shapeIdx[0]--;
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( shapeIdx ) )
      {
      RealType oldWeight =
        this->m_JointHistogramImages[whichHistogram]->GetPixel( shapeIdx );
      this->m_JointHistogramImages[whichHistogram]->SetPixel( shapeIdx,
        ( 1.0 - distance4) * newWeight + oldWeight );
      }
     }

  return;
}

template <class TListSample, class TOutput, class TCoordRep>
void
JointHistogramParzenShapeAndOrientationListSampleFunction<TListSample, TOutput, TCoordRep>
::IncrementJointHistogramForOrientation(
  RealType x, RealType y, RealType z, unsigned int whichHistogram )
{
  RealType newWeight = 1.0;

  // 2nd, the orientation histogram.  origin 0,0.  spacing of 1,1.
  //  need to be careful for wrap around in the 0 to 2*pi case.
  if( !this->m_JointHistogramImages[whichHistogram] )
    {
    this->m_JointHistogramImages[whichHistogram] =
      JointHistogramImageType::New();
    typename JointHistogramImageType::SpacingType spacing2;
    spacing2.Fill(1);
    typename JointHistogramImageType::PointType origin2;
    origin2.Fill(0);
    typename JointHistogramImageType::SizeType size2;
    size2.Fill( this->m_NumberOfJointHistogramBins );
    size2[0] = size2[0] + 2;
    this->m_JointHistogramImages[whichHistogram]->SetOrigin( origin2 );
    this->m_JointHistogramImages[whichHistogram]->SetSpacing( spacing2 );
    this->m_JointHistogramImages[whichHistogram]->SetRegions( size2 );
    this->m_JointHistogramImages[whichHistogram]->Allocate();
    this->m_JointHistogramImages[whichHistogram]->FillBuffer( 0 );
    }

  typename JointHistogramImageType::PointType orientPoint;
  RealType tp[2];
  tp[1] = 0.0;

  tp[0] = vcl_acos( z );

   // phi goes from 0.0 (+x axis) and wraps at 2 * PI
   // theta goes from 0.0 (+z axis) and wraps at PI
   // if x and y are 0.0 or very close, return phi == 0
   if( vnl_math_abs( x ) + vnl_math_abs( y ) < 1e-9 )
     {
     tp[1] = 0.0;
     }
   else
     {
     if( y == 0.0 )
       {
       if( x > 0.0 )
         {
         tp[1] = 0.0;
         }
       else
         {
         tp[1] = vnl_math::pi;
         }
       }
     else if( x == 0.0)
       {
       // avoid div by zero
       if( y > 0 )
         {
         tp[1] = vnl_math::pi_over_2;
         }
       else
         {
         tp[1] = 1.5 * vnl_math::pi;
         }
       }
     else if( x > 0.0 && y > 0.0 )
       { // first quadrant
       tp[1] = vcl_atan( y / x );
       }
     else if( x < 0.0 && y > 0.0)
       { // second quadrant
       tp[1] = vnl_math::pi + vcl_atan( y / x );
       }
     else if( x < 0.0 && y < 0.0 )
       { // third quadrant
       tp[1] =  vnl_math::pi + atan( y / x );
       }
     else
       { // fourth quadrant
       tp[1] = 2.0 * vnl_math::pi + atan( y / x );
       }
     }
   RealType psi = tp[0];
   RealType theta = tp[1];

  // note, if a point maps to 0 or 2*pi then it should contribute to both bins
  orientPoint[0] = theta / ( 2.0 * vnl_math::pi ) *
    ( this->m_NumberOfJointHistogramBins - 1) + 1;
  orientPoint[1] = psi / vnl_math::pi *
    ( this->m_NumberOfJointHistogramBins - 1 );

  ContinuousIndex<double, 2> orientCidx;
  this->m_JointHistogramImages[whichHistogram]->
    TransformPhysicalPointToContinuousIndex( orientPoint, orientCidx );

  typename JointHistogramImageType::IndexType orientIdx;

  /** Nearest neighbor interpolation */
  if( this->m_UseNearestNeighborIncrements )
    {
    orientIdx[0] = vcl_floor( orientCidx[0] + 0.5 );
    orientIdx[1] = vcl_floor( orientCidx[1] + 0.5 );
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( orientIdx ) )
      {
      RealType oldWeight =
        this->m_JointHistogramImages[whichHistogram]->GetPixel( orientIdx );
      this->m_JointHistogramImages[whichHistogram]->
        SetPixel( orientIdx, 1 + oldWeight );
      }
    }
  else
    {
    orientIdx[0] = static_cast<IndexValueType>( vcl_floor( orientCidx[0] ) );
    orientIdx[1] = static_cast<IndexValueType>( vcl_floor( orientCidx[1] ) );
    RealType distance1 = vcl_sqrt( vnl_math_sqr( orientCidx[0] - orientIdx[0] ) +
      vnl_math_sqr( orientCidx[1] - orientIdx[1] ) );
    orientIdx[0]++;
    RealType distance2 = vcl_sqrt( vnl_math_sqr( orientCidx[0] - orientIdx[0] ) +
      vnl_math_sqr( orientCidx[1] - orientIdx[1] ) );
    orientIdx[1]++;
    RealType distance3 = vcl_sqrt( vnl_math_sqr( orientCidx[0] - orientIdx[0] ) +
      vnl_math_sqr( orientCidx[1] - orientIdx[1] ) );
    orientIdx[0]--;
    RealType distance4 = vcl_sqrt( vnl_math_sqr( orientCidx[0] - orientIdx[0] ) +
      vnl_math_sqr( orientCidx[1] - orientIdx[1] ) );
    RealType sumDistance = distance1 + distance2 + distance3 + distance4;
    distance1 /= sumDistance;
    distance2 /= sumDistance;
    distance3 /= sumDistance;
    distance4 /= sumDistance;

    orientIdx[0] = static_cast<IndexValueType>( vcl_floor( orientCidx[0] ) );
    orientIdx[1] = static_cast<IndexValueType>( vcl_floor( orientCidx[1] ) );
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( orientIdx ) )
      {
      RealType oldWeight =
        this->m_JointHistogramImages[whichHistogram]->GetPixel( orientIdx );
      this->m_JointHistogramImages[whichHistogram]->SetPixel( orientIdx,
        ( 1.0 - distance1 ) * newWeight + oldWeight );
      }
    orientIdx[0]++;
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( orientIdx ) )
      {
      RealType oldWeight =
        this->m_JointHistogramImages[whichHistogram]->GetPixel( orientIdx );
      this->m_JointHistogramImages[whichHistogram]->SetPixel( orientIdx,
        ( 1.0 - distance2 ) * newWeight + oldWeight );
      }
    orientIdx[1]++;
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( orientIdx ) )
      {
      RealType oldWeight =
        this->m_JointHistogramImages[whichHistogram]->GetPixel( orientIdx );
      this->m_JointHistogramImages[whichHistogram]->SetPixel( orientIdx,
        ( 1.0 - distance3 ) * newWeight + oldWeight );
      }
    orientIdx[0]--;
    if( this->m_JointHistogramImages[whichHistogram]->
      GetLargestPossibleRegion().IsInside( orientIdx ) )
      {
      RealType oldWeight =
        this->m_JointHistogramImages[whichHistogram]->GetPixel(orientIdx );
      this->m_JointHistogramImages[whichHistogram]->SetPixel( orientIdx,
        ( 1.0 - distance4) * newWeight + oldWeight );
      }
    }

  // The last thing we do is copy the [1,] column to the [NBins+1,] column and
  // the [NBins,] column to the [0,] column --- circular boundary conditions.

  typedef itk::ImageRegionIteratorWithIndex<JointHistogramImageType> Iterator;
  Iterator tIter( this->m_JointHistogramImages[whichHistogram],
    this->m_JointHistogramImages[whichHistogram]->GetBufferedRegion() );
  for( tIter.GoToBegin(); !tIter.IsAtEnd(); ++tIter )
    {
    IndexType index = tIter.GetIndex();
    IndexType index2 = tIter.GetIndex();
    if( index[0] == 0 )
      {
      index2[0] = this->m_NumberOfJointHistogramBins;
      index2[1] = index[1];
     	tIter.Set(
     	  this->m_JointHistogramImages[whichHistogram]->GetPixel( index2 ) );
      }
    if( index[0] == this->m_NumberOfJointHistogramBins + 1 )
      {
      index2[0] = 1;
      index2[1] = index[1];
      tIter.Set(
        this->m_JointHistogramImages[whichHistogram]->GetPixel( index2 ) );
      }
    ++tIter;
    }
  return;
}

template <class TListSample, class TOutput, class TCoordRep>
void
JointHistogramParzenShapeAndOrientationListSampleFunction<TListSample, TOutput, TCoordRep>
::SetInputListSample( const InputListSampleType * ptr )
{
  Superclass::SetInputListSample( ptr );

  if( !this->GetInputListSample() )
    {
    return;
    }

  if( this->GetInputListSample()->Size() <= 1 )
    {
    itkWarningMacro( "The input list sample has <= 1 element." <<
      "Function evaluations will be equal to 0." );
    return;
    }

  const unsigned int Dimension =
    this->GetInputListSample()->GetMeasurementVectorSize();

  /**
   * Find the min/max values to define the histogram domain
   */
  Array<RealType> minValues( Dimension );
  minValues.Fill( NumericTraits<RealType>::max() );
  Array<RealType> maxValues( Dimension );
  maxValues.Fill( NumericTraits<RealType>::NonpositiveMin() );

  typename InputListSampleType::ConstIterator It
    = this->GetInputListSample()->Begin();
  while( It != this->GetInputListSample()->End() )
    {
    InputMeasurementVectorType inputMeasurement = It.GetMeasurementVector();
    for( unsigned int d = 0; d < Dimension; d++ )
      {
      if( inputMeasurement[d] < minValues[d] )
        {
        minValues[d] = inputMeasurement[d];
        }
      if( inputMeasurement[d] > maxValues[d] )
        {
        maxValues[d] = inputMeasurement[d];
        }
      }
    ++It;
    }
  for( unsigned int d = 0; d < 3; d++ )
    {
    this->m_JointHistogramImages[d] = NULL;
    }

  RealType L = static_cast<RealType>(
    this->GetInputListSample()->GetMeasurementVectorSize() );
  unsigned int D = static_cast<unsigned int>( 0.5 * ( -1 + vcl_sqrt( 1.0 +
    8.0 * L ) ) );

  It = this->GetInputListSample()->Begin();
  while( It != this->GetInputListSample()->End() )
    {
    InputMeasurementVectorType inputMeasurement = It.GetMeasurementVector();
    // convert to a tensor then get its shape and primary orientation vector
    typedef VariableSizeMatrix<RealType>                      TensorType;
    TensorType T( D, D );
    T.Fill( 0.0 );
    unsigned int index = 0;
    for( unsigned int i = 0; i < D; i++ )
      {
      for( unsigned int j = i; j < D; j++ )
        {
        T(i, j) = inputMeasurement( index++ );
        T(j, i) = T(i, j);
        }
      }
    // now decompose T into shape and orientation
    TensorType V;
    TensorType W;
    TensorType Tc = T;
    typedef DecomposeTensorFunction<TensorType> DecomposerType;
    typename DecomposerType::Pointer decomposer = DecomposerType::New();
    decomposer->EvaluateSymmetricEigenDecomposition( Tc, W, V );
    // now W holds the eigenvalues ( shape )

    // for each tensor sample, we add its content to the relevant histogram.
    RealType eigenvalue1 = W(2, 2);
    RealType eigenvalue2 = ( W(1, 1) + W(0, 0) ) * 0.5;
    if( eigenvalue1 > this->m_MaximumEigenvalue1 )
      {
      this->m_MaximumEigenvalue1 = eigenvalue1;
      }
    if( eigenvalue2 > this->m_MaximumEigenvalue2 )
      {
      this->m_MaximumEigenvalue2 = eigenvalue2;
      }
    if( eigenvalue1 < this->m_MinimumEigenvalue1 )
      {
      this->m_MinimumEigenvalue1 = eigenvalue1;
      }
    if( eigenvalue2 < this->m_MinimumEigenvalue2 )
      {
      this->m_MinimumEigenvalue2 = eigenvalue2;
      }
    ++It;
    }

  It = this->GetInputListSample()->Begin();
  while( It != this->GetInputListSample()->End() )
    {
    InputMeasurementVectorType inputMeasurement = It.GetMeasurementVector();
    // convert to a tensor then get its shape and primary orientation vector
    typedef VariableSizeMatrix<RealType>                      TensorType;
    TensorType T( D, D );
    T.Fill( 0.0 );
    unsigned int index = 0;
    for( unsigned int i = 0; i < D; i++ )
      {
      for( unsigned int j = i; j < D; j++ )
        {
        T(i, j) = inputMeasurement( index++ );
        T(j, i) = T(i, j);
        }
      }
    // now decompose T into shape and orientation
    TensorType V;
    TensorType W;
    TensorType Tc = T;
    typedef DecomposeTensorFunction<TensorType> DecomposerType;
    typename DecomposerType::Pointer decomposer = DecomposerType::New();
    decomposer->EvaluateSymmetricEigenDecomposition( Tc, W, V );
    // now W holds the eigenvalues ( shape )

    // for each tensor sample, we add its content to the relevant histogram.
    RealType eigenvalue1 = W(2, 2) - this->m_MinimumEigenvalue1;
    RealType eigenvalue2 = ( W(1, 1) + W(0, 0) ) * 0.5 -
      this->m_MinimumEigenvalue2;
    eigenvalue1 /= ( this->m_MaximumEigenvalue1 - this->m_MinimumEigenvalue1 );
    eigenvalue2 /= ( this->m_MaximumEigenvalue2 - this->m_MinimumEigenvalue2 );
    /** joint-hist model for the eigenvalues */
    this->IncrementJointHistogramForShape( eigenvalue1,eigenvalue2 );

    RealType x = V(2, 0);
    RealType y = V(2, 1);
    RealType z = V(2, 2);
    /** joint-hist model for the principal eigenvector */
    this->IncrementJointHistogramForOrientation( x, y, z, 1 );
    x = V(1, 0);
    y = V(1, 1);
    z = V(1, 2);
    /** joint-hist model for the second eigenvector */
    this->IncrementJointHistogramForOrientation( x, y, z, 2 );

    ++It;
    }

  for( unsigned int d = 0; d < 3; d++ )
    {
    typedef DiscreteGaussianImageFilter<JointHistogramImageType,
      JointHistogramImageType> GaussianFilterType;
    typename GaussianFilterType::Pointer gaussian = GaussianFilterType::New();
    gaussian->SetInput( this->m_JointHistogramImages[d] );
    gaussian->SetVariance( this->m_Sigma * this->m_Sigma );
    gaussian->SetMaximumError( 0.01 );
    gaussian->SetUseImageSpacing( false );
    gaussian->Update();

    typedef StatisticsImageFilter<JointHistogramImageType> StatsFilterType;
    typename StatsFilterType::Pointer stats = StatsFilterType::New();
    stats->SetInput( gaussian->GetOutput() );
    stats->Update();

    typedef DivideByConstantImageFilter<JointHistogramImageType, RealType,
      JointHistogramImageType> DividerType;
    typename DividerType::Pointer divider = DividerType::New();
    divider->SetInput( gaussian->GetOutput() );
    divider->SetConstant( stats->GetSum() );
    divider->Update();
    this->m_JointHistogramImages[d] = divider->GetOutput();
    }

	// Define static variable which_class and convert to string
	
	static int which_class=0;
	which_class++;
	std::string string;
	std::stringstream outstring;
	outstring<<which_class;
	string=outstring.str();
	
	std::cout << "Before Histogram 1" << std::endl; 
  	// Imagewriter 
    typedef ImageFileWriter< JointHistogramImageType >  WriterType;
	typename WriterType::Pointer      writer = WriterType::New();
	
	std::string output( "output_shape"+string+".nii.gz" );
	writer->SetFileName( output.c_str() );
	writer->SetInput(this->m_JointHistogramImages[0] );
	writer->Update();
	std::cout << "Before Histogram 2" << std::endl;
    
	typedef ImageFileWriter< JointHistogramImageType >  WriterType2;
	typename WriterType2::Pointer      writer2 = WriterType::New();
	std::string output2( "output_orientation"+string+".nii.gz" );
	writer2->SetFileName( output2.c_str() );
	writer2->SetInput(this->m_JointHistogramImages[1] );
	writer2->Update();
  
    
}

template <class TListSample, class TOutput, class TCoordRep>
TOutput
JointHistogramParzenShapeAndOrientationListSampleFunction<TListSample, TOutput, TCoordRep>
::Evaluate( const InputMeasurementVectorType &measurement ) const
{
  try
    {
    typedef BSplineInterpolateImageFunction<JointHistogramImageType>
      InterpolatorType;

    RealType probability = 1.0;
    for( unsigned int d = 0; d < 3; d++ )
      {
      typename JointHistogramImageType::PointType point;
      point[0] = measurement[d];

      typename InterpolatorType::Pointer interpolator = InterpolatorType::New();
      interpolator->SetSplineOrder( 3 );
      interpolator->SetInputImage( this->m_JointHistogramImages[d] );
      if( interpolator->IsInsideBuffer( point ) )
        {
        probability *= interpolator->Evaluate( point );
        }
      else
        {
        return 0;
        }
      }
    return probability;
    }
  catch(...)
    {
    return 0;
    }
    

    
    
}

/**
 * Standard "PrintSelf" method
 */
template <class TListSample, class TOutput, class TCoordRep>
void
JointHistogramParzenShapeAndOrientationListSampleFunction<TListSample, TOutput, TCoordRep>
::PrintSelf(
  std::ostream& os,
  Indent indent) const
{
  os << indent << "Sigma: " << this->m_Sigma << std::endl;
  os << indent << "Number of histogram bins: "
    << this->m_NumberOfJointHistogramBins << std::endl;
  os << indent << "Minimum eigenvalue 1: "
    << this->m_MinimumEigenvalue1;
  os << indent << "Minimum eigenvalue 2: "
    << this->m_MinimumEigenvalue2;
  os << indent << "Maximum eigenvalue 1: "
    << this->m_MaximumEigenvalue1;
  os << indent << "Maximum eigenvalue 2: "
    << this->m_MaximumEigenvalue2;

  if( this->m_UseNearestNeighborIncrements )
    {
    os << indent << "Use nearest neighbor increments." << std::endl;
    }
  else
    {
    os << indent << "Use linear interpolation for increments." << std::endl;
    }
}

} // end of namespace Statistics
} // end of namespace ants
} // end of namespace itk

#endif

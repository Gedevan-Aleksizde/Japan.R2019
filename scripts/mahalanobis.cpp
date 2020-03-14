#include <RcppArmadillo.h>
#include <Rcpp.h>
using namespace Rcpp;


// [[Rcpp::depends(RcppArmadillo)]]
// [[Rcpp::export]]
// http://arma.sourceforge.net/docs.html
DataFrame mahalanobis_pair(arma::mat Pixels) {
  int n_features = Pixels.n_cols;
  int n_points   = Pixels.n_rows;
  NumericVector d(n_points * (n_points-1)/2);
  NumericVector idx1(d.length());
  NumericVector idx2(d.length());
  arma::mat Corr = arma::inv_sympd(arma::cor(Pixels));
  arma::rowvec z = arma::zeros<arma::rowvec>(n_features);
  int r=0;
  for(int i=0; i < n_points; i++){
    for(int j=0; j < i; j++){
      z = Pixels.row(i) - Pixels.row(j);
      idx1[r] = i+1;
      idx2[r] = j+1;
      d[r] = as_scalar(z * Corr * z.as_col());
      r++;
    }
  }
  return DataFrame::create(_["num1"]=idx1,
                           _["num2"]=idx2,
                           _["mahalanobis"] = d) ;
}

// [[Rcpp::export]]
NumericVector get_feature(arma::mat Pixels){
  // rowwise
  for(int i=0; i < Pixels.n_rows; i++){
    Pixels.row(i).first()
    Pixels.row(i).mean();
  }
}
#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <gsl/gsl_errno.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_multifit.h>
#include <gsl/gsl_vector.h>

#include <assert.h>
#include <stdio.h>
#include <string.h>

#include "lcfit_tripod_c.h"

inline void check_model(value model)
{
  if(Wosize_val(model) / Double_wosize != TRIPOD_BSM_NPARAM) { \
    char err[200]; \
      sprintf(err, "Invalid model dimension: %lu [expected %zu]", \
          Wosize_val(model) / Double_wosize, \
          TRIPOD_BSM_NPARAM); \
      caml_invalid_argument(err); \
  }
}

/* OCaml records containing only floats are stored as arrays of doubles.
 * http://caml.inria.fr/pub/docs/manual-ocaml-4.00/manual033.html#htoc262 */
inline tripod_bsm_t convert_model(value model) {
    tripod_bsm_t m = {Double_field(model, 0),
                      Double_field(model, 1),
                      Double_field(model, 2),
                      Double_field(model, 3),
                      Double_field(model, 4),
                      Double_field(model, 5),
                      Double_field(model, 6),
                      Double_field(model, 7),
                      Double_field(model, 8) };
    return m;
}

/* Adapted from gsl-ocaml */
/* Attempt to raise an instance of Lcfit.Lcfit_error */
inline void lcfit_raise_exception(const char *msg, int gsl_errno)
{
    CAMLlocal2(exn_msg, exn_arg);
    exn_msg = copy_string(msg);
    exn_arg = alloc_small(2, 0);
    Field(exn_arg, 0) = Val_int(gsl_errno);
    Field(exn_arg, 1) = exn_msg;
    if(caml_named_value("lcfit_err") != NULL)
      raise_with_arg(*caml_named_value("lcfit_err"), exn_arg);
    else
      failwith("GSL error");
}

CAMLprim value
caml_lcfit_tripod_ll(value model, value c_value, value tx_value)
{
    CAMLparam3(model, c_value, tx_value);

    double c = Double_val(c_value), tx = Double_val(tx_value);

    check_model(model);

    tripod_bsm_t m = convert_model(model);

    double result = lcfit_tripod_ll(c, tx, &m);
    CAMLreturn(caml_copy_double(result));
}

/**
 * model (tripod_bsm)
 * pts   Array of 3-tuples, containing (distal_bl, pendant_bl, log_like)
 *
 * See: lcfit.ml
 */
CAMLprim value
caml_lcfit_tripod_fit(value model, value pts)
{
    CAMLparam2(model, pts);
    assert(Tag_val(pts) == 0 && "Input should be array-ish");

    size_t n = Wosize_val(pts), i;

    /* Verify arguments */
    if(n < TRIPOD_BSM_NVARYING) {
        char err[200];
        sprintf(err, "Insufficient points to fit (%zu)", n);
        caml_invalid_argument(err);
    }
    check_model(model);

    double *dist_bl = malloc(sizeof(double) * n),
           *pend_bl = malloc(sizeof(double) * n),
           *ll      = malloc(sizeof(double) * n);

    for(i = 0; i < n; i++) {
        // Check input
        assert(Wosize_val(Field(pts, i)) == 3);
        assert(Tag_val(Field(Field(pts, i), 0)) == Double_tag);
        assert(Tag_val(Field(Field(pts, i), 1)) == Double_tag);
        assert(Tag_val(Field(Field(pts, i), 2)) == Double_tag);

        dist_bl[i] = Double_val(Field(Field(pts, i), 0));
        pend_bl[i] = Double_val(Field(Field(pts, i), 1));
        ll[i]      = Double_val(Field(Field(pts, i), 2));
    }

    tripod_bsm_t m = convert_model(model);

    int return_code = lcfit_tripod_fit_bsm(n, dist_bl, pend_bl, ll, &m);

    free(dist_bl);
    free(pend_bl);
    free(ll);

    if(return_code) {
        lcfit_raise_exception(gsl_strerror(return_code), return_code);
    }

    CAMLlocal1(result);
    result = caml_alloc(TRIPOD_BSM_NPARAM * Double_wosize, Double_array_tag);
    double* m_arr = array_of_tripod_bsm(&m);
    for(i = 0; i < TRIPOD_BSM_NPARAM; i++)
        Store_double_field(result, i, m_arr[i]);
    free(m_arr);

    CAMLreturn(result);
}

CAMLprim value
caml_lcfit_tripod_jacobian(value model, value c_value, value tx_value)
{
    CAMLparam3(model, c_value, tx_value);

    check_model(model);
    tripod_bsm_t m = convert_model(model);

    double* jac = lcfit_tripod_jacobian(Double_val(c_value), Double_val(tx_value), &m);

    CAMLlocal1(result);
    result = caml_alloc(TRIPOD_BSM_NVARYING * Double_wosize, Double_array_tag);

    size_t i;
    for(i = 0; i < TRIPOD_BSM_NVARYING; ++i)
        Store_double_field(result, i, jac[i]);
    free(jac);
    CAMLreturn(result);
}

CAMLprim value
caml_lcfit_least_squares_scaling(value model, value pts)
{
    CAMLparam2(model, pts);

    check_model(model);
    const tripod_bsm_t m = convert_model(model);

    size_t n = Wosize_val(pts), i, j;
    const size_t p = 4;

    double dist_bl, pend_bl, ll;

    gsl_matrix* A = gsl_matrix_alloc(n, p), *cov = gsl_matrix_alloc(p, p);
    gsl_vector* y = gsl_vector_alloc(n), *x = gsl_vector_alloc(p);

    double coeffs[4];

    /* Pull values from input points */
    for(i = 0; i < n; i++) {
        // Check input
        assert(Wosize_val(Field(pts, i)) == 3);

        for(j = 0; j < 3; j++)
            assert(Tag_val(Field(Field(pts, i), j)) == Double_tag);

        dist_bl = Double_val(Field(Field(pts, i), 0));
        pend_bl = Double_val(Field(Field(pts, i), 1));
        ll      = Double_val(Field(Field(pts, i), 2));

        lcfit_tripod_nxx_coeff(&m, dist_bl, pend_bl, coeffs);
        gsl_vector_set(y, i, ll);
        for(j = 0; j < p; j++)
            gsl_matrix_set(A, i, j, coeffs[j]);
    }

    /* Perform the fit */
    gsl_multifit_linear_workspace* fit = gsl_multifit_linear_alloc(n, p);
    int gsl_result = gsl_multifit_linear(A, y, x, cov, coeffs, fit);

    /* Store in an OCaml double array */
    CAMLlocal1(result);
    result = caml_alloc(TRIPOD_BSM_NPARAM * Double_wosize, Double_array_tag);

    for(i = 0; i < p; i++)
        Store_double_field(result, i, gsl_vector_get(x, i));

    double* m_arr = array_of_tripod_bsm(&m);
    for(i = p; i < TRIPOD_BSM_NPARAM; i++)
        Store_double_field(result, i, m_arr[i]);
    free(m_arr);

    CAMLreturn(result);

    /* Clean up */
    gsl_matrix_free(A);
    gsl_matrix_free(cov);
    gsl_vector_free(y);
    gsl_vector_free(x);
    gsl_multifit_linear_free(fit);

    /* Check success */
    if(gsl_result != GSL_SUCCESS)
        lcfit_raise_exception(gsl_strerror(gsl_result), gsl_result);

    CAMLreturn(result);
}

/* vim: set ts=4 sw=4 : */
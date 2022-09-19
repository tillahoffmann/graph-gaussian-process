// Graph gaussian process with log link for Poisson observations.

functions {
    #include gptools_fft.stan
    #include gptools_kernels.stan
}

#include data.stan

parameters {
    vector[num_nodes] eta;
}

transformed parameters {
    // Evaluate covariance of the point at zero with everything else.
    vector[num_nodes] cov = gp_periodic_exp_quad_cov(X, rep_array(rep_vector(0, 1), 1), alpha, rep_vector(rho, 1), rep_vector(num_nodes, 1))[:, 1];
    cov[1] += epsilon;
}

model {
    eta ~ fft_gp(cov);
    y ~ poisson_log(eta);
}

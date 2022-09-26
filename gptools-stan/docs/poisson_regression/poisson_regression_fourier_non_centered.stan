// Graph gaussian process with log link for Poisson observations.

functions {
    #include gptools_fft.stan
    #include gptools_kernels.stan
    #include gptools_util.stan
}

data {
    #include data.stan
}

parameters {
    vector[n] z;
}

transformed parameters {
    vector[n] eta;
    {
        // Evaluate covariance of the point at zero with everything else and transform the white
        // noise. We wrap the evaluation in braces because Stan only writes top-level variables to
        // the output CSV files, and we don't need to store the entire covariance matrix.
        vector[n] cov = gp_periodic_exp_quad_cov(zeros(1), X, sigma, length_scale, n);
        cov[1] += epsilon;
        eta = fft_gp_transform(z, cov);
    }
}

model {
    // White noise prior (implies eta ~ fft_gp(...) and observation model.
    z ~ normal(0, 1);
    y ~ poisson_log(eta);
}

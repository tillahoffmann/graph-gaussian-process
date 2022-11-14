/**
Evaluate the in-degree of nodes in the directed acyclic graph induced by :code:`edges`. The node
labels of children must be ordered and each node must at least have a self loop. The function does
not check whether the graph is acyclic.

:param n: Number of nodes.
:param edge_index: Directed edges as a tuple of parent and child indices, i.e. the node labelled
  :code:`edge_index[1, i]` is the parent of the node labelled :code:`edge_index[2, i]`.

:returns: In-degree of each node.
*/
array [] int in_degrees(int n, array [,] int edge_index) {
    array [n] int count = rep_array(0, n);
    int previous = 0;
    for (i in 1:size(edge_index[2])) {
        int current = edge_index[2, i];
        if (previous > current) {
            reject("nodes are not ordered: ", previous, " > ", current);
        }
        if (previous != current && edge_index[1, i] != current) {
            reject("first edge of node ", i, " is not a self loop");
        }
        if (previous > 0 && count[previous] < 1) {
            reject("node ", i, " has no edges");
        }
        count[current] += 1;
        previous = current;
    }
    if (previous != n) {
        reject("expected ", n, " nodes but found ", previous);
    }
    return count;
}

/**
Evaluate the location and scale for a node given its parents.

:param y: State of :math:`k` parents.
:param x: Array of :math:`k + 1` locations in :math:`p` dimensions. The first row corresponds to
  the target node. Subsequent rows correspond to parents of the target node.
:param sigma: Amplitude of the covariance matrix.
:param length_scale: Correlation scale of the covariance matrix.
:param epsilon: Nugget variance.
:param predecessors: Labels of :math:`k` predecessors of the target node.
:returns: Location and scale parameters for the distribution of the node at :math:`x_1` given
  nodes :math:`j > 1`.
*/
vector conditional_loc_scale(vector y, array[] vector x, real sigma, real length_scale, real epsilon,
                             array [] int predecessors) {
    vector[2] loc_scale;
    if (size(predecessors) == 1) {
        loc_scale[1] = 0;
        loc_scale[2] = sqrt(sigma ^ 2 + epsilon);
    } else {
        // Evaluate the local covariance.
        matrix[size(predecessors), size(predecessors)] cov = add_diag(
            gp_exp_quad_cov(x[predecessors], sigma, length_scale), epsilon);
        vector[size(predecessors) - 1] v = mdivide_left_spd(cov[2:, 2:], cov[2:, 1]);
        loc_scale[1] = dot_product(v, y[predecessors[2:]]);
        loc_scale[2] = sqrt(cov[1, 1] - dot_product(v, cov[2:, 1]));
    }
    return loc_scale;
}

/**
Evaluate the log probability of a graph Gaussian process with zero mean.

.. warning::

    If a non-zero mean is required, it should be subtracted from the node states :math:`y`. This
    implementation mixes *centered* and *non-centered* parameterizations--an issue that should be
    fixed.

:param y: State of each node.
:param x: Position of each node.
:param sigma: Scale parameter for the covariance.
:param length_scale: Correlation length.
:param epsilon: Additional diagonal variance.
:param edges: Directed edges between nodes constituting a directed acyclic graph. Edges are stored
  as a matrix with shape `(2, m)`, where `m` is the number of edges. The first row comprises
  parents of children in the second row. The first row can have arbitrary order (except the first
  edge of each node must be a self loop), but the second row must be sorted.
:param degrees: In-degree of each node.

:returns: Log probability of the graph Gaussian process.
*/
real gp_graph_exp_quad_cov_lpdf(vector y, array [] vector x, real sigma, real length_scale,
                                array [,] int edges, array[] int degrees, real epsilon) {
    real lpdf = 0;
    int offset_ = 1;
    for (i in 1:size(x)) {
        int in_degree = degrees[i];
        vector[2] loc_scale = conditional_loc_scale(y, x, sigma, length_scale, epsilon,
                                                    segment(edges[1], offset_, in_degree));
        lpdf += normal_lpdf(y[i] | loc_scale[1], loc_scale[2]);
        offset_ += in_degree;
    }
    return lpdf;
}


/**
Transform white noise to a sample from a graph Gaussian process with zero mean. A mean can be
added after the transformation.

:param z: White noise for each node.
:param x: Position of each node.
:param sigma: Scale parameter for the covariance.
:param length_scale: Correlation length.
:param epsilon: Additional diagonal variance.
:param edges: Directed edges between nodes constituting a directed acyclic graph. Edges are stored
  as a matrix with shape `(2, m)`, where `m` is the number of edges. The first row comprises
  parents of children in the second row. The first row can have arbitrary order (except the first
  edge of each node must be a self loop), but the second row must be sorted.
:param degrees: In-degree of each node.

:returns: Sample from the Graph gaussian process.
*/
vector gp_graph_exp_quad_cov_transform(vector z, array [] vector x, real sigma, real length_scale,
                                       array [,] int edges, array [] int degrees, real epsilon) {
    vector[size(z)] y;
    int offset_ = 1;
    for (i in 1:size(x)) {
        int in_degree = degrees[i];
        vector[2] loc_scale = conditional_loc_scale(y, x, sigma, length_scale, epsilon,
                                                    segment(edges[1], offset_, in_degree));
        y[i] = loc_scale[1] + loc_scale[2] * z[i];
        offset_ += in_degree;
    }
    return y;
}

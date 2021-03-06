
``kr`` calculates the Kantorovich-Rubinstein distance between collections of placements (given by their place files) by its closed form formula

.. math::
    Z(P,Q) =
    \int_T \left| P(\tau(y)) - Q(\tau(y)) \right| \, \lambda(dy).

This is a generalization of the UniFrac distance (UniFrac can only place mass at leaves and cannot accomodate uncertainty).
There is a further generalization to an :math:`L^p` Zolotarev-type version:
for :math:`0 < p < \infty` we have the distances

.. math::

    Z_p(P,Q) =
    \left[\int_T \left| P(\tau(y)) - Q(\tau(y)) \right|^p \, \lambda(dy)\right]^{\frac{1}{p} \wedge 1}

which can be used to vary the impact of mass relative to transport.
A larger :math:`p` increases the impact of differences of mass, while a smaller :math:`p` emphasizes distance traveled.

Note that the significance p-values calculated by ``-s`` or ``--gaussian`` are not corrected for multiple comparison.

The assessment of significance is tricky for metagenomic sampling.
The randomization test (that seems to be very commonly used in association with UniFrac and that is implemented here with the ``-s`` flag) does not have wonderful properties when in the setting of incomplete sampling with non-independent observations.
This is commonly the case for metagenomic sampling.
Imagine, for example, that we have a random observation process on the tree equipped with some collection of "base observations."
Each process takes a random subset of those base observations and then throws down some number of reads for each observation in that set, the number of which has mean >> 1.
If the set of base observations is large compared to the number of sample observations, then two draws will always appear significantly different even though they are from the same underlying process.
Thus I would only trust a rejection of the null when sampling is quite deep and the same primers are used for the experiments being compared.


See `Evans and Matsen`_ for more details on phylogenetic KR.

.. _Evans and Matsen: http://arxiv.org/abs/1005.1699

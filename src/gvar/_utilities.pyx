import gvar as _gvar
from ._gvarcore import GVar
from ._gvarcore cimport GVar

import numpy
cimport numpy

from ._svec_smat import svec, smat
from ._svec_smat cimport svec, smat

from ._bufferdict import BufferDict

cdef extern from "math.h":
    double c_pow "pow" (double x,double y)
    double c_sin "sin" (double x)
    double c_cos "cos" (double x)
    double c_tan "tan" (double x)
    double c_sinh "sinh" (double x)
    double c_cosh "cosh" (double x)
    double c_tanh "tanh" (double x)
    double c_log "log" (double x)
    double c_exp "exp" (double x)
    double c_sqrt "sqrt" (double x)
    double c_asin "asin" (double x)
    double c_acos "acos" (double x)
    double c_atan "atan" (double x)

## utility functions ##
def rebuild(g, corr=0.0, gvar=_gvar.gvar):
    """ Rebuild ``g`` stripping correlations with variables not in ``g``.
        
    ``g`` is either an array of |GVar|\s or a dictionary containing
    |GVar|\s and/or arrays of |GVar|\s. ``rebuild(g)`` creates a new
    collection |GVar|\s with the same layout, means and covariance matrix
    as those in ``g``, but discarding all correlations with variables not
    in ``g``.
        
    If ``corr`` is nonzero, ``rebuild`` will introduce correlations 
    wherever there aren't any using ::
        
        cov[i,j] -> corr * sqrt(cov[i,i]*cov[j,j]) 
        
    wherever ``cov[i,j]==0.0`` initially. Positive values for ``corr`` 
    introduce positive correlations, negative values anti-correlations.
        
    Parameter ``gvar`` specifies a function for creating new |GVar|\s that
    replaces :func:`gvar.gvar` (the default).
            
    :param g: |GVar|\s to be rebuilt.
    :type g: array or dictionary
    :param gvar: Replacement for :func:`gvar.gvar` to use in rebuilding.
        Default is :func:`gvar.gvar`.
    :type gvar: :class:`gvar.GVarFactory` or ``None``
    :param corr: Size of correlations to introduce where none exist
        initially.
    :type corr: number
    :returns: Array or dictionary (gvar.BufferDict) of |GVar|\s  (same 
        layout as ``g``) where all correlations with variables other than
        those in ``g`` are erased.
    """
    cdef numpy.ndarray[numpy.double_t,ndim=2] gcov
    cdef unsigned int i,j,ng
    cdef float cr
    if hasattr(g,'keys'):
        ## g is a dict ##
        if not isinstance(g,BufferDict):
            g = BufferDict(g)
        buf = rebuild(g.flat,corr=corr,gvar=gvar)
        return BufferDict(g,buf=buf)
        ##
    else:
        ## g is an array ##
        g = numpy.asarray(g)
        if corr!=0.0:
            ng = g.size
            gcov = evalcov(g).reshape(ng,ng)
            cr = corr
            for i in range(ng):
                for j in range(i+1,ng):
                    if gcov[i,j]==0:
                        gcov[i,j] = cr*c_sqrt(gcov[i,i]*gcov[j,j])
                        gcov[j,i] = gcov[i,j]
            return gvar(mean(g),gcov.reshape(2*g.shape))
        else:
            return gvar(mean(g),evalcov(g))
        ##
##
def mean(g):
    """ Extract means from :class:`gvar.GVar`\s in ``g``.
        
    ``g`` can be a |GVar|, an array of |GVar|\s, or a dictionary containing
    |GVar|\s or arrays of |GVar|\s. Result has the same layout as ``g``.
    """
    cdef unsigned int i
    cdef GVar gi
    cdef numpy.ndarray[numpy.double_t,ndim=1] buf
    if isinstance(g,GVar):
        return g.mean
    if hasattr(g,'keys'):
        if not isinstance(g,BufferDict):
            g = BufferDict(g)
    else:
        g = numpy.asarray(g)
    buf = numpy.zeros(g.size,float)
    for i,gi in enumerate(g.flat):
        buf[i] = gi.v
    return BufferDict(g,buf=buf) if g.shape is None else buf.reshape(g.shape)
##
def fmt(g, ndecimal=None, sep='', d=None):
    """ Format :class:`gvar.GVar`\s in ``g``.
        
    ``g`` can be a |GVar|, an array of |GVar|\s, or a dictionary containing
    |GVar|\s or arrays of |GVar|\s. Each |GVar| ``gi`` in ``g`` is replaced
    by the string generated by ``gi.fmt(ndecimal,sep)``. Result has same 
    structure as ``g``.
    """
    cdef unsigned int i
    cdef GVar gi
    if d is not None:
        ndecimal = d        # legacy name
    if isinstance(g,GVar):
        return g.fmt(ndecimal=ndecimal,sep=sep)
    if hasattr(g,'keys'):
        if not isinstance(g,BufferDict):
            g = BufferDict(g)
    else:
        g = numpy.asarray(g)
    buf = []
    for i,gi in enumerate(g.flat):
        buf.append(gi.fmt(ndecimal=ndecimal,sep=sep))
    return BufferDict(g,buf=buf) if g.shape is None else numpy.reshape(buf,g.shape)
##
def sdev(g):
    """ Extract standard deviations from :class:`gvar.GVar`\s in ``g``.
        
    ``g`` can be a |GVar|, an array of |GVar|\s, or a dictionary containing
    |GVar|\s or arrays of |GVar|\s. Result has the same layout as ``g``.
    """
    cdef unsigned int i
    cdef GVar gi
    cdef numpy.ndarray[numpy.double_t,ndim=1] buf
    if isinstance(g,GVar):
        return g.sdev
    if hasattr(g,'keys'):
        if not isinstance(g,BufferDict):
            g = BufferDict(g)
    else:
        g = numpy.asarray(g)
    buf = numpy.zeros(g.size,float)
    for i,gi in enumerate(g.flat):
        buf[i] = gi.sdev
    return BufferDict(g,buf=buf) if g.shape is None else buf.reshape(g.shape)
##
def var(g):
    """ Extract variances from :class:`gvar.GVar`\s in ``g``.
        
    ``g`` can be a |GVar|, an array of |GVar|\s, or a dictionary containing
    |GVar|\s or arrays of |GVar|\s. Result has the same layout as ``g``.
    """
    cdef unsigned int i
    cdef GVar gi
    cdef numpy.ndarray[numpy.double_t,ndim=1] buf
    if isinstance(g,GVar):
        return g.var
    if hasattr(g,'keys'):
        if not isinstance(g,BufferDict):
            g = BufferDict(g)
    else:
        g = numpy.asarray(g)
    buf = numpy.zeros(g.size,float)
    for i,gi in enumerate(g.flat):
        buf[i] = gi.var
    return BufferDict(g,buf=buf) if g.shape is None else buf.reshape(g.shape)
##
def uncorrelated(g1,g2):
    """ Return ``True`` if |GVar|\s in ``g1`` uncorrelated with those in ``g2``.
        
    ``g1`` and ``g2`` can be |GVar|\s, arrays of |GVar|\s, or dictionaries
    containing |GVar|\s or arrays of |GVar|\s.
    """
    cdef GVar g
    cdef smat cov
    cdef unsigned int i
    # collect indices from g1 and g2 separately
    s = [set(),set()]
    for i,gi in enumerate([g1,g2]):
        if not hasattr(gi,'flat'):
            if isinstance(gi,GVar):
                gi = numpy.array([gi])
            elif hasattr(gi,'keys'):
                gi = BufferDict(gi)
            else:
                gi = numpy.asarray(gi)
        for g in gi.flat:
            s[i].update(g.d.indices())
    if not s[0].isdisjoint(s[1]):
        # index sets overlap, so g1 and g2 not orthogonal
        return False
    # collect indices connected to g1 by the covariance matrix
    cov = g.cov
    s0 = set()
    for i in s[0]:
        s0.update(cov.rowlist[i].indices())
    # orthogonal if indices in g1 not connected to indices in g2 by cov
    return s0.isdisjoint(s[1])
##
def evalcov(g):
    """ Compute covariance matrix for elements of 
    array/dictionary ``g``.
        
    If ``g`` is an array of |GVar|\s, ``evalcov`` returns the
    covariance matrix as an array with shape ``g.shape+g.shape``.
    If ``g`` is a dictionary whose values are |GVar|\s or arrays of 
    |GVar|\s, the result is a doubly-indexed dictionary where 
    ``cov[k1,k2]`` is the covariance for ``g[k1]`` and ``g[k2]``.
    """
    cdef int a,b,ng,i,j,nc
    cdef numpy.ndarray[numpy.double_t,ndim=2] ans
    cdef numpy.ndarray[numpy.double_t,ndim=1] rowda
    cdef numpy.ndarray[numpy.int8_t,ndim=1] rowda_empty
    cdef GVar ga,gb
    cdef svec da,db,row
    cdef smat cov
    if hasattr(g,"keys"):
        ## convert g to list and call evalcov; repack as double dict ##
        if not isinstance(g,BufferDict):
            g = BufferDict(g)
        gcov = evalcov(g.flat)
        ansd = BufferDict()
        for k1 in g:
            for k2 in g:
                ansd[k1,k2] = gcov[g.slice(k1),g.slice(k2)]
        return ansd
        ##
    g = numpy.asarray(g)
    g_shape = g.shape
    g = g.flat
    ng = len(g)
    ans = numpy.zeros((ng,ng),float)
    cov = g[0].cov 
    nc = len(cov.rowlist)
    covd = []
    if True:
        rowda = numpy.zeros(nc,float)   ## stores rowlist[i].dot(da)s
        rowda_empty = numpy.ones(nc,numpy.int8)
        for a in range(ng):
            ga = g[a]
            da = ga.d
            rowda_empty.fill(True)  ## reset
            for b in range(a,ng):
                gb = g[b]
                db = gb.d
                for i in range(db.size):
                    j = db.v[i].i
                    if rowda_empty[j]:   
                        row = cov.rowlist[j]
                        rowda_empty[j] = False
                        rowda[j] = row.dot(da)
                    ans[a,b] += rowda[j]*db.v[i].v
                if a!=b:
                    ans[b,a] = ans[a,b]
    else:      
        for a in range(ng):
            ga = g[a]
            covd.append(cov.dot(ga.d))
            ans[a,a] = ga.d.dot(covd[-1])
            for b in range(a):
                ans[a,b] = ga.d.dot(covd[b])
                ans[b,a] = ans[a,b]
    return ans.reshape(2*g_shape)
##
def wsum_der(numpy.ndarray[numpy.double_t,ndim=1] wgt,glist):
    """ weighted sum of |GVar| derivatives """
    cdef GVar g
    cdef smat cov
    cdef double w
    cdef unsigned int ng,i
    cdef numpy.ndarray[numpy.double_t,ndim=1] ans
    ng = len(glist)
    assert ng==len(wgt),"wgt and glist have different lengths."
    cov = glist[0].cov
    ans = numpy.zeros(len(cov),float)
    for i in range(wgt.shape[0]):
        w = wgt[i]
        g = glist[i]
        assert g.cov is cov,"Incompatible |GVar|\s."
        for i in range(g.d.size):
            ans[g.d.v[i].i] += w*g.d.v[i].v
    return ans 
##
def wsum_gvar(numpy.ndarray[numpy.double_t,ndim=1] wgt,glist):
    """ weighted sum of |GVar|\s """
    cdef svec wd
    cdef double wv,w
    cdef GVar g
    cdef smat cov
    cdef unsigned int ng,i,nd,size
    cdef numpy.ndarray[numpy.double_t,ndim=1] der
    cdef numpy.ndarray[numpy.int_t,ndim=1] idx
    ng = len(glist)
    assert ng==len(wgt),"wgt and glist have different lengths."
    cov = glist[0].cov
    der = numpy.zeros(len(cov),float)
    wv = 0.0
    for i in range(ng): #w,g in zip(wgt,glist):
        w = wgt[i]
        g = glist[i]
        assert g.cov is cov,"Incompatible |GVar|\s."
        wv += w*g.v
        for i in range(g.d.size):
            der[g.d.v[i].i] += w*g.d.v[i].v
    idx = numpy.zeros(len(cov),int) # der.nonzero()[0]
    nd = 0
    for i in range(der.shape[0]):
        if der[i]!=0:
            idx[nd] = i
            nd += 1
    wd = svec(nd)
    for i in range(nd):
        wd.v[i].i = idx[i]
        wd.v[i].v = der[idx[i]]
    return GVar(wv,wd,cov)
##
def fmt_values(outputs, ndecimal=None, ndigit=None):
    """ Tabulate :class:`gvar.GVar`\s in ``outputs``. 
        
    :param outputs: A dictionary of :class:`gvar.GVar` objects. 
    :param ndecimal: Format values ``v`` using ``v.fmt(ndecimal)``.
    :type ndecimal: ``int`` or ``None``
    :returns: A table (``str``) containing values and standard 
        deviations for variables in ``outputs``, labeled by the keys
        in ``outputs``.
    """
    if ndigit is not None:
        ndecimal = ndigit
    ans = "Values:\n"
    for vk in outputs:
        ans += "%19s: %-20s\n" % (vk,outputs[vk].fmt(ndecimal))
    return ans
##
def fmt_errorbudget(outputs, inputs, ndecimal=2, percent=True, ndigit=None):
    """ Tabulate error budget for ``outputs[ko]`` due to ``inputs[ki]``.
       
    For each output ``outputs[ko]``, ``fmt_errorbudget`` computes the
    contributions to ``outputs[ko]``'s standard deviation coming from the
    |GVar|\s collected in ``inputs[ki]``. This is done for each key
    combination ``(ko,ki)`` and the results are tabulated with columns and
    rows labeled by ``ko`` and ``ki``, respectively. If a |GVar| in
    ``inputs[ki]`` is correlated with other |GVar|\s, the contribution from
    the others is included in the ``ki`` contribution as well (since
    contributions from correlated |GVar|\s cannot be resolved). The table
    is returned as a string.
        
    :param outputs: Dictionary of |GVar|\s for which an error budget 
        is computed.
    :param inputs: Dictionary of: |GVar|\s, arrays/dictionaries of 
        |GVar|\s, or lists of |GVar|\s and/or arrays/dictionaries of
        |GVar|\s. ``fmt_errorbudget`` tabulates the parts of the standard
        deviations of each ``outputs[ko]`` due to each ``inputs[ki]``.
    :param ndecimal: Number of decimal places displayed in table.
    :type ndecimal: ``int``
    :param percent: Tabulate % errors if ``percent is True``; otherwise
        tabulate the errors themselves.
    :type percent: boolean
    :returns: A table (``str``) containing the error budget. 
        Output variables are labeled by the keys in ``outputs``
        (columns); sources of uncertainty are labeled by the keys in
        ``inputs`` (rows).
    """
    ## collect partial errors ##
    if ndigit is not None:
        ndecimal = ndigit       # legacy name
    err = {}
    for ko in outputs:
        for ki in inputs:
            inputs_ki = inputs[ki]
            if hasattr(inputs_ki,'keys') or not hasattr(inputs_ki,'__iter__'):
                inputs_ki = [inputs_ki]
            err[ko,ki] = outputs[ko].partialvar(*inputs_ki)**0.5                
    ##
    ## form table ##
    lfmt = "%19s:"+len(outputs)*("%10."+str(ndecimal)+"f")+"\n"
    hfmt = "%20s"+len(outputs)*("%10s")+"\n"
    if percent:
        val = numpy.array([abs(outputs[vk].mean) 
                                for vk in outputs])/100.
        ans = "Partial % Errors:\n"
    else:
        val = 1.
        ans = "Partial Errors:\n"
    ans += hfmt % (("",)+tuple(outputs.keys()))
    ans += (20+len(outputs)*10)*'-'+"\n"
    for ck in inputs:
        verr = numpy.array([err[vk,ck] for vk in outputs])/val
        ans += lfmt%((ck,)+tuple(verr))
    ans += (20+len(outputs)*10)*'-'+"\n"
    ans += lfmt%(("total",)+tuple(numpy.array([outputs[vk].sdev 
                                    for vk in outputs])/val))
    ##
    return ans
##
##

## bootstrap_iter, raniter, ranseed, svd, valder ##
def bootstrap_iter(g, n=None, svdcut=None, svdnum=None, rescale=True):
    """ Return iterator for bootstrap copies of ``g``. 
        
    The gaussian variables (|GVar| objects) in array (or dictionary) ``g``
    collectively define a multidimensional gaussian distribution. The
    iterator created by :func:`bootstrap_iter` generates an array (or
    dictionary) of new |GVar|\s whose covariance matrix is the same as
    ``g``'s but whose means are drawn at random from the original ``g``
    distribution. This is a *bootstrap copy* of the original distribution.
    Each iteration of the iterator has different means (but the same
    covariance matrix). 
        
    :func:`bootstrap_iter` also works when ``g`` is a single |GVar|, in
    which case the resulting iterator returns bootstrap copies of the
    ``g``.
        
    :param g: An array (or dictionary) of objects of type |GVar|.
    :type g: array or dictionary or BufferDict
    :param n: Maximum number of random iterations. Setting ``n=None``
        (the default) implies there is no maximum number.
    :param svdcut: If positive, replace eigenvalues of the covariance
        matrix of ``g`` with ``svdcut*(max eigenvalue)``; if negative,
        discards eigenmodes with eigenvalues smaller than 
        ``svdcut*(max eigenvalue)``; ignore if set to ``None``.
    :type svdcut: ``None`` or number
    :param svdnum: If positive, keep only the modes with the largest 
        ``svdnum`` eigenvalues in the covariance matrix for ``g``; 
        ignore if set to ``None`` or negative.
    :type svdnum: ``None`` or positive ``int``
    :param rescale: Covariance matrix is rescaled so that diagonal elements
        equal ``1`` before applying *svd* cuts if ``rescale=True``.
    :type rescale: bool
    :returns: An iterator that returns bootstrap copies of ``g``.
    """
    if hasattr(g,'keys'):
        g = BufferDict(g)
    else:
        g = numpy.asarray(g)
    s = SVD(evalcov(g.flat),svdcut=svdcut,svdnum=svdnum,
            rescale=rescale,compute_delta=True)
    g_flat = g.flat if s.delta is None else (g.flat + s.delta)
    wgt = s.decomp(1)
    nwgt = len(wgt)
    count = 0
    while (n is None) or (count<n):
        count += 1
        z = numpy.random.normal(0.0,1.,nwgt)
        buf = g_flat + sum(zi*wi for zi,wi in zip(z,wgt))
        if g.shape is None:
            yield BufferDict(g,buf=buf)
        elif g.shape == ():
            yield next(buf.flat)
        else:
            yield buf.reshape(g.shape)
        # yield BufferDict(g,buf=buf) if g.shape is None else buf.reshape(g.shape)
    raise StopIteration
## 
def raniter(g,n=None, svdcut=None, svdnum=None, rescale=True):
    """ Return iterator for random samples from distribution ``g``
        
    The gaussian variables (|GVar| objects) in array (or dictionary) ``g`` 
    collectively define a multidimensional gaussian distribution. The 
    iterator defined by :func:`raniter` generates an array (or dictionary)
    containing random numbers drawn from that distribution, with 
    correlations intact. 
        
    The layout for the result is the same as for ``g``. So an array of the
    same shape is returned if ``g`` is an array. When ``g`` is a dictionary, 
    individual entries ``g[k]`` may be |GVar|\s or arrays of |GVar|\s, 
    with arbitrary shapes.
        
    :func:`raniter` also works when ``g`` is a single |GVar|, in which case
    the resulting iterator returns random numbers drawn from the
    distribution specified by ``g``.
        
    :param g: An array (or dictionary) of objects of type |GVar|; or a |GVar|.
    :type g: array or dictionary or BufferDict or GVar
    :param n: Maximum number of random iterations. Setting ``n=None``
        (the default) implies there is no maximum number.
    :param svdcut: If positive, replace eigenvalues of the covariance
        matrix of ``g`` with ``svdcut*(max eigenvalue)``; if negative,
        discards eigenmodes with eigenvalues smaller than 
        ``svdcut*(max eigenvalue)``; ignore if set to ``None``.
    :type svdcut: ``None`` or number
    :param svdnum: If positive, keep only the modes with the largest 
        ``svdnum`` eigenvalues in the covariance matrix for ``g``; 
        ignore if set to ``None`` or negative.
    :type svdnum: ``None`` or positive ``int``
    :param rescale: Covariance matrix is rescaled so that diagonal elements
        equal ``1`` if ``rescale=True``.
    :type rescale: bool
    :returns: An iterator that returns random arrays or dictionaries
        with the same shape as ``g`` drawn from the gaussian distribution 
        defined by ``g``.
    """
    if hasattr(g,'keys'):
        g = BufferDict(g)
    else:
        g = numpy.asarray(g)
    g_mean = mean(g.flat)
    s = SVD(evalcov(g.flat),svdcut=svdcut,svdnum=svdnum,rescale=rescale)
    wgt = s.decomp(1)
    nwgt = len(wgt)
    count = 0
    while count!=n:
        count += 1
        z = numpy.random.normal(0.0,1.,nwgt)
        buf = g_mean + sum(zi*wi for zi,wi in zip(z,wgt))
        if g.shape is None:
            yield BufferDict(g,buf=buf)
        elif g.shape == ():
            yield next(buf.flat)
        else:
            yield buf.reshape(g.shape)
        # yield BufferDict(g,buf=buf) if g.shape is None else buf.reshape(g.shape)
    raise StopIteration
##
def ranseed(seed):
    """ Seed random number generators with tuple ``seed``.
        
    Argument ``seed`` is a :class:`tuple` of integers that is used to seed
    the random number generators used by :mod:`numpy` and  
    :mod:`random` (and therefore by :mod:`gvar`). Reusing 
    the same ``seed`` results in the same set of random numbers.
        
    :param seed: A tuple of integers.
    :type seed: tuple
    """
    seed = tuple(seed)
    numpy.random.seed(seed)
##   
class SVD(object):
    """ SVD decomposition of a pos. sym. matrix. 
        
    :class:`SVD` is a function-class that computes the eigenvalues and
    eigenvectors of a positive symmetric matrix ``mat``. Eigenvalues that
    are small (or negative, because of roundoff) can be eliminated or
    modified using *svd* cuts. Typical usage is::
            
        >>> mat = [[1.,.25],[.25,2.]]
        >>> s = SVD(mat)
        >>> print(s.val)             # eigenvalues
        [ 0.94098301  2.05901699]
        >>> print(s.vec[0])          # 1st eigenvector (for s.val[0])
        [ 0.97324899 -0.22975292]
        >>> print(s.vec[1])          # 2nd eigenvector (for s.val[1])
        [ 0.22975292  0.97324899]
            
        >>> s = SVD(mat,svdcut=0.6)  # force s.val[i]>=s.val[-1]*0.6
        >>> print(s.val)
        [ 1.2354102   2.05901699]
        >>> print(s.vec[0])          # eigenvector unchanged
        [ 0.97324899 -0.22975292]
        
        >>> s = SVD(mat)
        >>> w = s.decomp(-1)         # decomposition of inverse of mat
        >>> invmat = sum(numpy.outer(wj,wj) for wj in w)
        >>> print(numpy.dot(mat,invmat))    # should be unit matrix
        [[  1.00000000e+00   2.77555756e-17]
         [  1.66533454e-16   1.00000000e+00]]
            
    Input parameters are:
        
    :param mat: Positive, symmetric matrix.
    :type mat: 2-d sequence (``numpy.array`` or ``list`` or ...)
    :param svdcut: If positive, replace eigenvalues of ``mat`` with 
        ``svdcut*(max eigenvalue)``; if negative, discard eigenmodes with 
        eigenvalues smaller than ``svdcut`` times the maximum eigenvalue.
    :type svdcut: ``None`` or number ``(|svdcut|<=1)``.
    :param svdnum: If positive, keep only the modes with the largest 
        ``svdnum`` eigenvalues; ignore if set to ``None``.
    :type svdnum: ``None`` or int
    :param compute_delta: Compute ``delta`` (see below) if ``True``; set 
        ``delta=None`` otherwise.
    :type compute_delta: boolean
    :param rescale: Rescale the input matrix to make its diagonal elements 
        equal to 1.0 before diagonalizing.
        
    The results are accessed using:
        
    ..  attribute:: val
        
        An ordered array containing the eigenvalues or ``mat``. Note
        that ``val[i]<=val[i+1]``.
        
    ..  attribute:: vec
        
        Eigenvectors ``vec[i]`` corresponding to the eigenvalues 
        ``val[i]``. 
        
    ..  attribute:: D
        
        The diagonal matrix used to precondition the input matrix if
        ``rescale==True``. The matrix diagonalized is ``D M D`` where ``M``
        is the input matrix. ``D`` is stored as a one-dimensional vector of
        diagonal elements. ``D`` is ``None`` if ``rescale==False``.
        
    ..  attribute:: kappa 
        
        Ratio of the smallest to the largest eigenvector in the 
        unconditioned matrix (after rescaling if ``rescale=True``)
        
    ..  attribute:: delta
        
        A vector of ``gvar``\s whose means are zero and whose 
        covariance matrix is what was added to ``mat`` to condition 
        its eigenvalues. Is ``None`` if ``svdcut<0`` or 
        ``compute_delta==False``.
    """
    def __init__(self, mat,svdcut=None,svdnum=None,compute_delta=False,
                 rescale=False):
        super(SVD,self).__init__()
        self.svdcut = svdcut
        self.svdnum = svdnum
        if rescale:
            mat = numpy.asarray(mat)
            D = (mat.diagonal())**(-0.5)
            DmatD = mat*D
            DmatD = (DmatD.transpose()*D).transpose()
            self.D = D
        else:
            DmatD = mat
            self.D = None
        vec,val,dummy = numpy.linalg.svd(DmatD) 
        vec = numpy.transpose(vec) # now 1st index labels eigenval
        ## guarantee that sorted, with smallest val[i] first ##
        vec = numpy.array(vec[-1::-1])
        val = numpy.array(val[-1::-1])
        self.kappa = val[0]/val[-1] if val[-1]!=0 else None  # min/max eval
        self.delta = None
        ##
        ## svd cuts ##
        if (svdcut is None or svdcut==0.0) and (svdnum is None or svdnum<=0):
            self.val = val
            self.vec = vec
            return
        ## restrict to svdnum largest eigenvalues ##
        if svdnum is not None and svdnum>0:
            val = val[-svdnum:]
            vec = vec[-svdnum:]
        ##
        ## impose svdcut on eignevalues ##
        if svdcut is None or svdcut==0:
            self.val = val
            self.vec = vec
            return 
        valmin = abs(svdcut)*val[-1]
        if svdcut>0:
            ## force all eigenvalues >= valmin ##
            dely = None
            for i in range(len(val)): 
                if val[i]<valmin:
                    if compute_delta:
                        if dely is None:
                            dely = vec[i]*_gvar.gvar(0.0,(valmin-val[i])**0.5)
                        else:
                            dely += vec[i]*_gvar.gvar(0.0,(valmin-val[i])**0.5)
                    val[i] = valmin
                else:
                    break
            self.val = val
            self.vec = vec
            self.delta = dely if (self.D is None or dely is None) else dely/self.D
            return 
            ##
        else:
            ## discard modes with eigenvalues < valmin ##
            for i in range(len(val)): 
                if val[i]>=valmin:
                    break
            self.val = val[i:]
            self.vec = vec[i:]
            return  # val[i:],vec[i:],kappa,None
            ##
        ##
        ##
    ##
    def decomp(self,n=1):
        """ Vector decomposition of input matrix raised to power ``n``.
            
        Computes vectors ``w[i]`` such that
            
            mat**n = sum_i numpy.outer(w[i],w[i])
                
        where ``mat`` is the original input matrix to :class:`svd`. This 
        decomposition cannot be computed if the input matrix was rescaled
        (``rescale=True``) except for ``n=1`` and ``n=-1``.
            
        :param n: Power of input matrix.
        :type n: number
        :returns: Array ``w`` of vectors.
        """
        if self.D is None:
            w = numpy.array(self.vec)
            for j,valj in enumerate(self.val):
                w[j] *= valj**(n/2.)
        else:
            if n!=1 and n!=-1:
                raise ValueError(           #
                    "Can't compute decomposition for rescaled matrix.")
            w = numpy.array(self.vec)
            Dfac = self.D**(-n)
            for j,valj in enumerate(self.val):
                w[j] *= Dfac*valj**(n/2.)
        return w
    ##
##        
def valder(v): 
    """ Convert array ``v`` of numbers into an array of |GVar|\s.
        
    The |GVar|\s created by ``valder(v)`` have means equal to the
    values ``v[i]`` and standard deviations of zero. If ``v`` is
    one-dimensional, for example, ``valder(v)`` is functionally 
    equivalent to::
        
        newgvar = gvar.gvar_factory()
        numpy.array([newgvar(vi,0.0) for vi in v])
        
    The use of ``newgvar`` to create the |GVar|\s means that these
    variables are incompatible with those created by ``gvar.gvar``. 
    More usefully, it also means that the vector of derivatives ``x.der``
    for any |GVar| ``x`` formed from elements of ``vd = valder(v)``
    correspond to derivatives with respect to ``vd``: that is, ``x.der[i]``
    is the derivative of ``x`` with respect to ``vd.flat[i]``.
        
    In general, the shape of the array returned by ``valder`` is the
    same as that of ``vv``.
    """
    try:
        v = numpy.asarray(v,float)
    except ValueError:
        raise ValueError("Bad input.")
    gv_gvar = _gvar.gvar_factory()
    return gv_gvar(v,numpy.zeros(v.shape,float))
##
##


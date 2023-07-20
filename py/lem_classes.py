import itertools
#import numpy as np
import random
import pandas as pd
import numpy as np
import math
#
# Parcel
#
class Parcel:
    pix = itertools.count(0)

    def __init__(self, ident, area, land_use):
        self.ix = next(Parcel.pix)
        # This is to just remind me of the members
        self.ident = ident
        self.land_use = land_use   # this is numerical (0 ... L)
        self.area = area
        # self.land_use_index = Allocation.all_lucs.index(self.land_use)

    def __str__(self):
        s = ""
        s = "Parcel %d with identifier: %s" % (self.ix, self.ident)
        s += ".  Area: %.2f, Land Use: %s" % (self.area, self.land_use)
        return s

class Parcel2:
    pix = itertools.count(0)

    def __init__(self, ident, area, land_use):
        self.ix = next(Parcel.pix)
        # This is to just remind me of the members
        self.ident = ident
        self.land_use = land_use   # this is numerical (0 ... L)
        self.area = area
        # self.land_use_index = Allocation.all_lucs.index(self.land_use)

    def __str__(self):
        s = ""
        s = "Parcel %d with identifier: %s" % (self.ix, self.ident)
        s += ".  Area: %.2f, Land Use: %s" % (self.area, self.land_use)
        return s


class Allocation:
    aix = itertools.count(0)
    total_area = 0.0
    n_lucs = 0
    all_lucs = 0
    initial_allocation = None
    n_alloc = None
    parcels0 = list()
    p_areas_prop = list()
    n_satisfied_reps = 0
    sample_id=0
    
    def __init__(self, parcels=set()):
        self.ix = next(Allocation.aix)
        self.parcels = parcels
        self.indicators = {}
    
    @classmethod
    def randomAllocation_2(cls, nchanged, p_mean, p_sd, p_min, p_max, sample_id, luc_changes):
        copy_parcels = []
        for p in Allocation.parcels0:
            copy_parcels.append(Parcel(p.ident, p.area, p.land_use))
        i = 0
        luc_matrix = np.zeros((11,11))
        parcel_luc_changes = {}
        while i<nchanged:
            i +=1
            s = np.random.normal(p_mean,p_sd)
            if s<p_min:
                s=p_min
            if s>p_max:
                s=p_max
            # find 1st parcel with area > s (in proportion)
            if cls.p_areas_prop[-1] > s:
                index = next(x[0] for x in enumerate(cls.p_areas_prop) if x[1] > s)
            else:
                index = np.random.randint(0, len(cls.parcels0) - 1)
            # randomly change its land use
            p = copy_parcels[index]
            iluc1 = Allocation.all_lucs.index(p.land_use)
            tmp_list = list(cls.all_lucs)
            tmp_list.remove(p.land_use)
            p.land_use = random.choice(tmp_list)
            iluc2 = Allocation.all_lucs.index(p.land_use)
            #luc_matrix[iluc1,iluc2]+=p.area
            if parcel_luc_changes.__contains__(index):
                parcel_luc_changes[index]['second']=iluc2
                parcel_luc_changes[index]['area']=p.area
            else:
                parcel_luc_changes[index]={'first':iluc1, 'second':iluc2,'area':p.area}
        for index in parcel_luc_changes:
            luc1 = parcel_luc_changes[index]['first']
            luc2 = parcel_luc_changes[index]['second']
            area = parcel_luc_changes[index]['area']
            luc_matrix[luc1,luc2]+=area
        #line = str(a_id)
        #for j in range(11):
        #    for k in range(11):
        #        line+="\t"+str(luc_matrix[j,k])
        #if luc_writer!="":
        #    luc_writer.write(line+"\n")
        luc_list = list(cls.all_lucs)
        for j in range(11):
            for k in range(11):
                c = luc_matrix[j,k]
                if c>0:
                    luc_changes.append({
                        'sample_id':sample_id,
                        'from_luc':luc_list[j],
                        'to_luc':luc_list[k],
                        'changed_area': luc_matrix[j,k]
                    })
        return cls(copy_parcels)
    
    def calculate_indicators(self, matrixA):
        areas = {}
        for l in list(matrixA.index):
            areas[l] = [0.0]
        for p in self.parcels:
            areas[p.land_use][0] += p.area
        areas_df = pd.DataFrame.from_dict(areas)
        self.indicators = pd.DataFrame.dot(areas_df, matrixA)
    
    def __str__(self):
        s = "Allocation %d with indicators %s " % (self.ix, self.indicators.to_string())
        return s

# class indicator value
# common data: ndi
#              array with all indicator values through all random allocations
#              dict with {indicator:[representatives]}
# class method: discretize each indicator (takes allocations as parameter)
# (for this we consider the 25th, 50th and 75th percentiles)
# ( it could be written more generic too...)
# object data: double with threshold value
#              string with indicator name
# object methods: def __str__(self)

class Indicator:
    pix = itertools.count(0)
    #ndi = Config.getint("thresholds", "indDiscretization")
    ndi = 20
    indRep = {}
    n_indicators = 0
    def __init__(self, name, threshold):
        self.ix = next(Indicator.pix)
        self.name = name
        self.threshold = threshold
    @classmethod
    def createIndicators2(cls, allocations):
        for ind_str, reps in cls.indRep.items():
            cls.n_indicators+=1
            vals = {}
            for i in range(Allocation.n_alloc):
                vals[i] = allocations[i].indicators.iloc[0][ind_str]
            sorted_vals = sorted(vals.items(), key=lambda kv: kv[1])
            npp = Indicator.ndi
            n_alloc = len(allocations)
            for r in reps:
                r.delta_rts={}
            index_1=0
            index_2=0
            for p in range(npp+1):
                if p==0:
                    threshold = sorted_vals[0][1]-1
                else:
                    index0 = int((p-1)*n_alloc/npp)
                    index1 = int(p*n_alloc/npp-1)
                    for r in reps:
                        r.delta_rts[p-1]=set()
                        for k in range(index0,index1):
                            r.delta_rts[p-1].add(allocations[sorted_vals[k][0]])
                    threshold = sorted_vals[index1][1]
                    if p==npp:
                        threshold+=1
                ind = cls(ind_str, threshold)
                for r in reps:
                    r.list_ind_thresholds.append(ind)
    # this function is supposed to be called only for initial count
    @classmethod
    def calculate_satisfied_reps(cls, allocations):
        for a in allocations:
            a.n_satisfied_reps=0
            for ind_str, reps in cls.indRep.items():
                indicator_val = a.indicators.iloc[0][ind_str]
                for r in reps:
                    # r.sign * a.indicators.iloc[0][self.indicator_str] >= self.sign * t.threshold:
                    if (r.sign*indicator_val >= r.sign*r.threshold):
                        a.n_satisfied_reps += 1
    # (zc: set min and max indicator index based on initial allocation
    # this function is supposed to be called only in initialization
    @classmethod
    def set_rep_ind_min_max(cls, init_allocation,init_n_satisfied):
        # y = init_n_satisfied
        y = random.randrange(init_n_satisfied+1)
        x = random.sample(range(1,cls.n_indicators),y)
        a=init_allocation
        a.n_satisfied_reps=0
        i=0 # count the index of indicators
        for ind_str, reps in cls.indRep.items():
            indicator_val = a.indicators.iloc[0][ind_str]
            for j in range(len(reps)):
                r = reps[j]
                if i in x and j==0: # init allocation satisfy this rep
                    t0 = r.list_ind_thresholds[0].threshold # check the lowest threshold
                    if r.sign*indicator_val >= r.sign*t0: # the lowest satisfies
                        r.threshold_index_min = 0
                        r.threshold_index_max = 0
                        for k in range(1,len(r.list_ind_thresholds)): # search for the highest satisfied
                            tk = r.list_ind_thresholds[k].threshold
                            if r.sign*indicator_val < r.sign*tk:
                                r.threshold_index_max = k-1
                                break
                    else: # the highest satisfied
                        r.threshold_index_max = len(r.list_ind_thresholds)-1 # the highest threshold index
                        r.threshold_index_min = len(r.list_ind_thresholds)-1
                        for k in range(1,len(r.list_ind_thresholds)): # search for the highest satisfied
                            tk = r.list_ind_thresholds[len(r.list_ind_thresholds)-1-k].threshold
                            if r.sign*indicator_val < r.sign*tk:
                                r.threshold_index_min = len(r.list_ind_thresholds)-k+1
                                break
                else: # init allocation doesn't satisfy this rep
                    t0 = r.list_ind_thresholds[0].threshold # check the lowest threshold
                    if r.sign*indicator_val >= r.sign*t0: # the lowest satisfies
                        r.threshold_index_max = len(r.list_ind_thresholds)-1 # the highest doesn't satisfy
                        r.threshold_index_min = len(r.list_ind_thresholds)-1
                        for k in range(1,len(r.list_ind_thresholds)): # search for the highest satisfied
                            tk = r.list_ind_thresholds[k].threshold
                            if r.sign*indicator_val < r.sign*tk:
                                r.threshold_index_min = k  # the lowest one that doesn't satisfy
                                break
                    else: # the highest satisfied
                        r.threshold_index_min = 0 # the lowest that doesn't satisfy
                        r.threshold_index_max = 0
                        for k in range(1,len(r.list_ind_thresholds)): # search for the highest satisfied
                            tk = r.list_ind_thresholds[len(r.list_ind_thresholds)-1-k].threshold
                            if r.sign*indicator_val < r.sign*tk:
                                r.threshold_index_max = len(r.list_ind_thresholds)-k
                                break
                if r.threshold_index_max<2:
                    r.threshold_index_max = 2 # min=max=0 not allowed
                if r.threshold_index_min > len(r.list_ind_thresholds)-3:
                    r.threshold_index_min = len(r.list_ind_thresholds)-3 # min=max = max not allowed
            i+=1
    # (zc: set min and max indicator index based on initial allocation
    # this function is supposed to be called only in initialization
    @classmethod
    def set_rep_init_threshold(cls):
        for ind_str, reps in cls.indRep.items():
            r0=reps[0]
            m0=int((r0.threshold_index_min+r0.threshold_index_max)/2)
            r0.threshold_index = m0
            r0.threshold= r0.list_ind_thresholds[m0].threshold 
            if len(reps)>1:
                r1 = reps[1]
                m1 = int((r1.threshold_index_min+r1.threshold_index_max)/2)
                if m1==m0 and m1<r1.threshold_index_max:
                    m1 +=1
                r1.threshold_index = m1
                r1.threshold =r1.list_ind_thresholds[m1].threshold
    # -zc)
    def __str__(self):
        s = 'Indicator %s with ix=%d and threshold value %.2f ' % (self.name, self.ix, self.threshold)
        return s
    # end added by zc

# the indicators are associated to the representative
# so, each representative object has a list of indicators (ordered by threshold value)
# when generating each representative, populate the indRep dictionary at Indicator

class Representative:
    # rix = itertools.count(0)
    # chosenIndicators = set()
    def __init__(self, inforep, matrixA, index):
        self.ix = index # next(Representative.rix)
        self.indicator_str = inforep['Indicator']
        self.indicator = matrixA.columns.get_loc(self.indicator_str)  # ??
        self.sign = 1 if inforep['Direction'] == 'Higher' else -1
        self.b = None 
        self.threshold = 0
        self.threshold_index = 0
        self.list_ind_thresholds = []
        self.threshold_index_min=0
        self.threshold_index_max=0
        # Representative.chosenIndicators.add(self.indicator_str)
        if self.indicator_str not in Indicator.indRep:
            Indicator.indRep[self.indicator_str] = [self]
        else:
            Indicator.indRep[self.indicator_str].append(self)
        self.alpha_rts = {}  # whether indicator t holds for scenario s
        self.delta_rts = {}
    def __str__(self):
        s = "Representative %d cares about (%s): %d" % (self.ix, self.indicator_str, self.sign)
        return s


class Histogram:
    def __init__(self, lb, ub):
        self.lb = lb
        self.ub = ub
    def __str__(self):
        s = ""
        for i in range(len(self.lb)):
            s += str(i + 1) + " in [" + str(self.lb[i]) + "," + str(self.ub[i]) + "]\n"
        return s

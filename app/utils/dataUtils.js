import Keygaps from "keygaps"

export function meltTimeSeries(data) {
    return Keygaps.fillValues({
        values: data,
        yVariable: 'value',
        keyFunction: (input) => [input.fieldValue, input.key],
        valueFunction: () => {
            let obj = {};
            obj['fieldValue'] = arguments[0][0];
            obj['key'] = arguments[0][1];
            return obj;
        }
    }).values
}

export function makeTimeSeriesData(fieldValues, cfTimeSeriesGroup, melt) {

    // If not melting the data (keygaps) return the data sorted
    if (!melt) {
        let unMeltedData = _.map(fieldValues, fv => {
            return {
                key: fv,
                values: _.map(cfTimeSeriesGroup[fv].top(Infinity), obj => {
                    return {
                        fieldValue: fv,
                        key: obj.key,
                        value: obj.value.count
                    }
                })
            }
        });
        unMeltedData.forEach(f => {
            f.values.sort((a, b) => a.key - b.key);
        });
        return unMeltedData;
    }

    // This will take all of the timestamp values for a fields, say status = 200 and status = 304, gather the values into one array
    let values = _.flatten(_.map(fieldValues, fv => {
        return  _.map(cfTimeSeriesGroup[fv].top(Infinity), obj => {
            return {
                fieldValue: fv,
                key: obj.key,
                value: obj.value.count
            }
        })
    }));

    let meltedData = meltTimeSeries(values);
    let groupedData = _.groupBy(meltedData, 'fieldValue');
    let finalData = _.map(_.keys(groupedData), k => {
        return {
            key: k,
            values: groupedData[k]
        }
    });
    _.each(finalData, f => {
        f.values.sort((a, b) => a.key - b.key);
    });
    return finalData;

}

export function makeD3Stream(key, values) {
    return [{
        key: key,
        values: values
    }];
}

export function makeMultiD3Stream(key, values) {
    return _.map(values, v => {
        return {key: v.key, values: [{key: key, value: v.value}] }
    })
}


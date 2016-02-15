import { Component, PropTypes } from "react"
import ReactDOM from "react-dom";
import d3 from "d3"
import nv from "nvd3"
import cx from "classnames";

class HorizontalBarChart extends Component {
    constructor(props, context) {
        super(props, context);
        this.state = {};
    }
    shouldComponentUpdate(props) {
        //console.debug(`shouldComponentUpdate: Updating with data: ${JSON.stringify(props.data)}`);
        if (this.chart == null) {
            this.initChart(props);
        } else {
            d3.select(ReactDOM.findDOMNode(this)).datum(props.data).transition().duration(1000).call(this.chart);
        }
        return false;
    }
    componentWillReceiveProps(nextProps) {
        //console.debug(`componentWillReceiveProps: Updating with data: ${JSON.stringify(nextProps.data)}`);
        if (this.chart == null) {
            this.initChart(nextProps);
        }
    }
    color() {
        if (this.props.lookupColor == null) return null;
        return (d, i) => this.props.lookupColor(this.props.field, d.key != null ? "" + d.key : d.data.key);
    }
    initChart(props) {
        //console.debug(`data: ${JSON.stringify(this.props.data, null, ' ')}`);
        nv.addGraph(() => {
            this.chart = nv.models.multiBarHorizontalChart()
                .x(d => d.key)
                .y(d => d.value)
                .margin({left: 100})
                .valueFormat(d3.format('d'))
                .duration(300)
                .groupSpacing(.1)
                //.stacked(props.stacked != null ? props.stacked : true)
                //.barColor(d3.scale.category20().range());
                .color(this.color() || d3.scale.category20().range());

            this.chart.yAxis.tickFormat(d3.format('d'));
            //this.chart.xAxis.axisLabelDistance(10);

            d3.select(ReactDOM.findDOMNode(this)).datum(props.data).transition().duration(1000).call(this.chart);
            this.chart.multibar.dispatch.on('elementClick', e => {
                this.onClick({
                    field: props.field,
                    key: e.data.key,
                    value: e.data.value
                });
                // No longer in latest nvd3 version
                //return nv.tooltip.cleanup();
            });
            nv.utils.windowResize(this.chart.update);

            //this.chart.dispatch.on('stateChange', e =>  nv.log('New State:', JSON.stringify(e)) );
            //this.chart.state.dispatch.on('change', state => nv.log('state', JSON.stringify(state)) );

            return this.chart;
        });
    }
    componentDidMount() {
        this.initChart(this.props);
    }
    filtersContainItem(item) {
        return _.findIndex(this.props.filters, item) !== -1;
    }
    onClick(item) {
        //console.debug(`Clicked on ${JSON.stringify(item, null, ' ')}`);
        if (this.filtersContainItem(item)) {
            return this.props.removeFilter(item);
        } else {
            return this.props.addFilter(item);
        }
    }
    render() {
        const { chartSize } = this.props;
        let classes = cx({
            'chart-med': chartSize == null || chartSize == 'med',
            'chart-large': chartSize == 'large',
            'svg-quick-chart': true
        });
        return (
            <svg className={classes}></svg>
        )
    }
}

HorizontalBarChart.propTypes = {
    data: PropTypes.array.isRequired,
    field: PropTypes.string.isRequired,
    topSize: PropTypes.number.isRequired,
    filters: PropTypes.array.isRequired,
    chartSize: PropTypes.oneOf(['med', 'large']),
    lookupColor: PropTypes.func
};

export default HorizontalBarChart;

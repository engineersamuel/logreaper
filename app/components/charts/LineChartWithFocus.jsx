import { Component, PropTypes } from "react"
import ReactDOM from "react-dom";
import d3 from "d3"
import nv from "nvd3"
import cx from "classnames";

class LineChartWithFocus extends Component {
    constructor(props, context) {
        super(props, context);
        this.state = {};
    }
    componentDidMount() {
        this.initChart(this.props);

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
        const { d3TimeFormat } = props;
        //console.debug(`data: ${JSON.stringify(this.props.data, null, ' ')}`);
        return nv.addGraph(() => {
            this.chart = nv.models.lineWithFocusChart()
                .x(d => d.key)
                .y(d => d.value)
                .brushExtent([props.minX, props.maxX])
                .color(this.color() || d3.scale.category20().range());

            this.chart.xAxis.tickFormat(d => (d3TimeFormat != null ? d3TimeFormat : d3.time.format('%I:%M:%S'))(new Date(d)) );
            this.chart.x2Axis.tickFormat(d => (d3TimeFormat != null ? d3TimeFormat : d3.time.format('%I:%M:%S'))(new Date(d)) );
            this.chart.yAxis.tickFormat(d3.format(',.2f'));
            this.chart.y2Axis.tickFormat(d3.format(',.2f'));
            this.chart.useInteractiveGuideline(true);

            // consider also d3.time.scale.utc()
            this.chart.xScale(d3.time.scale());

            d3.select(ReactDOM.findDOMNode(this)).datum(props.data).call(this.chart);
            //this.chart.lineChart.dispatch.on('elementClick', (e) => {
            //    this.onClick({
            //        field: props.field,
            //        key: e.data.key,
            //        value: e.data.value
            //    });
            //    nv.tooltip.cleanup();
            //});
            nv.utils.windowResize(this.chart.update);

            return this.chart;
        });
    }
    filtersContainItem(item) {
        return _.findIndex(this.props.filters, item) !== -1;
    }
    //onClick(item) {
    //    console.debug(`Clicked on ${JSON.stringify(item, null, ' ')}`);
    //    if (this.filtersContainItem(item)) {
    //        return this.props.removeFilter(item);
    //    } else {
    //        return this.props.addFilter(item);
    //    }
    //}
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

LineChartWithFocus.propTypes = {
    data: PropTypes.array.isRequired,
    field: PropTypes.string.isRequired,
    minX: PropTypes.number.isRequired,
    maxX: PropTypes.number.isRequired,
    filters: PropTypes.array.isRequired,
    chartSize: PropTypes.oneOf(['med', 'large']),
    lookupColor: PropTypes.func,
    d3TimeFormat: PropTypes.func
};

export default LineChartWithFocus;

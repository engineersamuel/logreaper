import { Component, PropTypes } from "react"
import ReactDOM from "react-dom";
import d3 from "d3"
import nv from "nvd3"
import cx from "classnames";

class DiscreteBarChart extends Component {
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
        if (this.props.lookupColor == null) return null
        return (d, i) => this.props.lookupColor(this.props.field, d.key != null ? "" + d.key : d.data.key);
    }
    initChart(props) {
        const {staggerLabels, showValues, showYAxis, rotateLabels, margin} = props;
        nv.addGraph(() => {
            this.chart = nv.models.discreteBarChart()
                .x(d => d.key)
                .y(d => d.value)
                .staggerLabels(staggerLabels != null ? staggerLabels : false)
                .valueFormat(d3.format('d'))
                .showValues(showValues != null ? showValues : true)
                .duration(300)
                .showYAxis(showYAxis != null ? showYAxis : false)
                //.color(d3.scale.category20().range());
                .color(this.color() || d3.scale.category20().range());

            if (rotateLabels != null) {
                this.chart.rotateLabels(rotateLabels)
            }

            if (margin != null) {
                this.chart.margin(margin)
            }

            this.chart.yAxis.tickFormat(d3.format('d'));
            d3.select(ReactDOM.findDOMNode(this)).datum(props.data).transition().duration(1000).call(this.chart);
            this.chart.discretebar.dispatch.on('elementClick', (e) => {
                this.onClick({
                    field: props.field,
                    key: e.data.key,
                    value: e.data.value
                });
                //nv.tooltip.cleanup();
            });
            nv.utils.windowResize(this.chart.update);

            return this.chart;
        });
    }
    filtersContainItem(item) {
        return _.findIndex(this.props.filters, item) !== -1;
    }
    onClick(item) {
        console.debug(`Clicked on ${JSON.stringify(item, null, ' ')}`);
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

DiscreteBarChart.propTypes = {
    data: PropTypes.array.isRequired,
    field: PropTypes.string.isRequired,
    topSize: PropTypes.number.isRequired,
    filters: PropTypes.array.isRequired,
    chartSize: PropTypes.oneOf(['med', 'large']),
    rotateLabels: PropTypes.number,
    margin: PropTypes.object,
    lookupColor: PropTypes.func
};

export default DiscreteBarChart;

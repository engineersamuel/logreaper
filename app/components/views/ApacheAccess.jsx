import { Component, PropTypes } from "react"
import shallowEqual from "react-pure-render/shallowEqual"
import { Alert, Row, Col, Glyphicon } from "react-bootstrap"
import Slider from 'rc-slider'

import AppBlock             from "../AppBlock.jsx"
import Spacer               from "../Spacer.jsx"
import TopCounts            from "../stats/TopCounts.jsx"
import Filtering            from "../filters/Filtering.jsx"
import HorizontalBarChart   from "../charts/HorizontalBarChart.jsx"
import DiscreteBarChart     from "../charts/DiscreteBarChart.jsx"
import LineChartWithFocus   from "../charts/LineChartWithFocus.jsx"
import LogDataGrid          from "../grid/LogDataGrid.jsx"

import * as DataUtils       from "../../utils/dataUtils"

class ApacheAccess extends Component {
    constructor(props, context) {
        super(props, context);
        this.state = _.assign({
            sliderValue: this.props.sliderValue || 5,
            // Filters are in the form of {field: '', value: ''}
            filters: this.props.filters || []
        }, this.props.file.viewModelOpts);
        this.updateSliderValue = this.updateSliderValue.bind(this);
        this.addFilter = this.addFilter.bind(this);
        this.removeFilter = this.removeFilter.bind(this);
        this.lookupColor = this.lookupColor.bind(this);
    }

    //shouldComponentUpdate(nextProps, nextState) {
    //    return !shallowEqual(this.props.progress, nextProps.progress);
    //}

    componentWillUnmount() {
        if (_.isFunction(this.state.cleanUp)) {
            this.state.cleanUp();
        }
    }

    componentWillReceiveProps(nextProps) {
        this.setState(_.assign(this.state, nextProps.viewModelOpts))
    }

    // http://react-component.github.io/slider/examples/slider.html
    updateSliderValue(e) {
        this.setState({
            sliderValue: _.isNumber(e) ? e : e.target.value
        });
    }

    lookupColor(field, key) {
        return this.state.lookupColor(field, key);
    }

    addFilter(item) {
        let newFilters;
        if (_.findIndex(this.state.filters, item) === -1) {
            newFilters = _.cloneDeep(this.state.filters);
            newFilters.push(item);
            this.reCalculateFilters(newFilters, item.field);
        } else {
            console.warn("Attempting to add a filter that already exists: " + (JSON.stringify(item)));
        }
    }

    removeFilter(item) {
        let newFilters;
        if (item.field === 'timestamp') {
            this.removeRangeFilter();
        } else {
            newFilters = _.reject(this.state.filters, item);
            this.reCalculateFilters(newFilters, item.field);
        }
    }

    reCalculateFilters(filters, field, deferUpdate) {
        var buildDimName, currentFieldFilterValues, currentFieldFilters, lowerCaseFirstChar;
        if (deferUpdate == null) {
            deferUpdate = false;
        }
        lowerCaseFirstChar = (str) => str.charAt(0).toLowerCase() + str.slice(1);
        buildDimName = (field) => (lowerCaseFirstChar(field)) + "Dim";
        currentFieldFilters = _.filter(filters, (f) => f.field === field );
        currentFieldFilterValues = _.map(currentFieldFilters, (f) => f.key );
        if (currentFieldFilterValues.length === 0) {
            this.state['dims'][buildDimName(field)].filterAll();
        } else {
            this.state['dims'][buildDimName(field)].filter((x) => {
                let found = false;
                for (var i = 0; i < currentFieldFilterValues.length; i++) {
                    if (currentFieldFilterValues[i] === x) {
                        found = true;
                        break;
                    }
                }
                return found;
            });
        }
        if (deferUpdate === false) {
            this.setState({
                filters: filters
            });
        }
    }

    renderTopCount(obj) {
        let hasNoItems = this.state.groups[`${obj.field}Group`].size() == 1 && this.state.groups[`${obj.field}Group`].top(1)[0].value.count == 0;
       return (
           <AppBlock title={`Top ${obj.field}`} key={obj.field} render={!hasNoItems}>
               <TopCounts
                   group={this.state.groups[`${obj.field}Group`]}
                   filters={this.state.filters}
                   addFilter={this.addFilter}
                   removeFilter={this.removeFilter}
                   field={obj.field}
                   title={`Top ${obj.field} counts`}
                   topSize={obj.topSize}
                   cfSize={this.state.cfSize}
                   truncate={Infinity}
                   inline={false}
                   lookupColor={this.lookupColor}
                   tooltip={`Total ${obj.field} counts based on the selected filters`}>
               </TopCounts>
           </AppBlock>
       )
    }

    render() {
        if (this.state.cfSize == null) return null;
        if (this.state.cfSize == 0 ) {
            return <Alert bsStyle="warning">No lines parsed.  This may be due to a log that contains few lines, none of which match the expected expressions.</Alert>
        }
        //console.debug(`Filters: ${JSON.stringify(this.state.filters, null, ' ')}`);

        // Use makeMultiD3Stream in conjunction with the HorizontalBarChart since it uses multiple streams
        //let topIpCounts = DataUtils.makeMultiD3Stream('IP', this.state.groups.ipGroup.top(this.state.sliderValue));
        let topIpCounts = DataUtils.makeD3Stream('IP', this.state.groups.ipGroup.top(this.state.sliderValue));
        let topStatusCounts = DataUtils.makeD3Stream('Status', this.state.groups.statusGroup.top(this.state.sliderValue));
        let topMethodCounts = DataUtils.makeD3Stream('Method', this.state.groups.methodGroup.top(this.state.sliderValue));

        let timeSeriesStatusCounts = DataUtils.makeTimeSeriesData(this.state.statusesToDisplay, this.state.groups.timestampGroups);

        const cap = 250;
        let gridData = this.state.dims.dynDim.top(cap);
        // Add the idx in for each line for the grid to select on
        gridData.forEach((l, idx) => l.idx = idx);

        // Define the top counts with metadata to map over
        //let topCountDict = [
        //    { field: 'status', topSize: Infinity },
        //    { field: 'method', topSize: Infinity },
        //    { field: 'uriStem', topSize: this.state.sliderValue },
        //    { field: 'ip', topSize: this.state.sliderValue }
        //];
        //let topCountElements = topCountDict.map(obj => this.renderTopCount(obj));

        return (
            <div ref="apache-access-view">
                <Row>
                    <Col md={12}>
                        <h3>Log Counts by Http Code</h3>
                        <LineChartWithFocus
                            data={timeSeriesStatusCounts}
                            field='status'
                            minX={this.state.minDate}
                            maxX={this.state.maxDate}
                            filters={this.state.filters}
                            resetRangeFilter={this.resetRangeFilter}
                            addRangeFilter={this.addRangeFilter}
                            removeRangeFilter={this.removeRangeFilter}
                            lookupColor={this.lookupColor}
                            d3TimeFormat={this.state.d3TimeFormat}
                            chartSize="large"
                        ></LineChartWithFocus>
                    </Col>
                </Row>
                <Spacer />
                <Filtering removeFilter={this.removeFilter} filters={this.state.filters}></Filtering>
                <p>Showing top <strong>{this.state.sliderValue}</strong> results (Slide to visualize more/less)</p>
                <Spacer />
                <Slider min={1} defaultValue={this.state.sliderValue} max={20} onChange={this.updateSliderValue}></Slider>
                <Spacer />
                <Row>
                    <Col md={12}>
                        <h3 className="title">
                            <span>Apache Access Stats</span>
                            <small> ({this.state.cfSize} log entries parsed spanning ~{this.state.durationHumanized})</small>
                        </h3>
                    </Col>
                    {/*topCountElements*/}
                </Row>
                <Row>
                    <Col md={6}>
                        {this.renderTopCount({ field: 'status', topSize: Infinity })}
                    </Col>
                    <Col md={6}>
                        <DiscreteBarChart
                            title='Top Status Counts'
                            data={topStatusCounts}
                            field='status'
                            filters={this.state.filters}
                            addFilter={this.addFilter}
                            removeFilter={this.removeFilter}
                            lookupColor={this.lookupColor}
                            topSize={this.state.sliderValue}
                            showYAxis={true}>
                        </DiscreteBarChart>
                    </Col>
                </Row>
                <hr/>
                <Row>
                    <Col md={6}>
                        {this.renderTopCount({ field: 'method', topSize: Infinity })}
                    </Col>
                    <Col md={6}>
                        <DiscreteBarChart
                            title='Top Method Counts'
                            data={topMethodCounts}
                            field='method'
                            filters={this.state.filters}
                            addFilter={this.addFilter}
                            removeFilter={this.removeFilter}
                            topSize={this.state.sliderValue}
                            showYAxis={true}>
                        </DiscreteBarChart>
                    </Col>
                </Row>
                <hr/>
                <Row>
                    <Col md={6}>
                        {this.renderTopCount({ field: 'ip', topSize: this.state.sliderValue })}
                    </Col>
                    <Col md={6}>
                        <DiscreteBarChart
                            title='Top IP Counts'
                            data={topIpCounts}
                            field='ip'
                            filters={this.state.filters}
                            addFilter={this.addFilter}
                            removeFilter={this.removeFilter}
                            topSize={this.state.sliderValue}
                            chartSize='med'
                            rotateLabels={45}
                            margin={{bottom: 75, right: 50}}
                            showYAxis={true}>
                        </DiscreteBarChart>
                    </Col>
                </Row>
                <hr/>
                <Row>
                    <Col md={12}>
                        {this.renderTopCount({ field: 'uriStem', topSize: this.state.sliderValue })}
                    </Col>
                </Row>
                <Row>
                    <Col md={6}>
                        <Spacer />
                        <Spacer />
                    </Col>
                    <Col md={12}>
                        <LogDataGrid
                            data={gridData}
                            idProperty="idx"
                            columns={[
                                { name: 'timestamp', title: 'Timestamp', render: (v) => (new Date(v).toLocaleString())},
                                { name: "ip", title: 'IP'},
                                { name: 'user', title: 'User'},
                                { name: 'method', title: 'Method'},
                                { name: 'uriStem', title: 'URI Stem'},
                                { name: 'status', title: 'Status'},
                                { name: 'bytes', title: 'Bytes' },
                                { name: 'referer', title: 'Referrer'},
                                { name: 'userAgent', title: 'User Agent'}
                            ]}
                            cap={cap}
                            isPaged={true}
                            height={500}>
                        </LogDataGrid>
                    </Col>
                </Row>

            </div>
        );
    }
}

ApacheAccess.propTypes = {
    file: PropTypes.object.isRequired
};

export default ApacheAccess;

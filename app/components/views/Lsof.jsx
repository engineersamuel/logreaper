import { Component, PropTypes } from "react"
import shallowEqual from "react-pure-render/shallowEqual"
import { Alert, Row, Col, Glyphicon } from "react-bootstrap"
import Slider from 'rc-slider'

import Spacer               from "../Spacer.jsx"
import TopCounts            from "../stats/TopCounts.jsx"
import Filtering            from "../filters/Filtering.jsx"
import HorizontalBarChart   from "../charts/HorizontalBarChart.jsx"
import DiscreteBarChart     from "../charts/DiscreteBarChart.jsx"
import LineChartWithFocus   from "../charts/LineChartWithFocus.jsx"
import LogDataGrid          from "../grid/LogDataGrid.jsx"

import * as DataUtils       from "../../utils/dataUtils"

class Lsof extends Component {
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
    }

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

    addFilter(item) {
        let newFilters;
        if (_.findIndex(this.state.filters, item) === -1) {
            // TODO -- doubt I need this clone here, refactor
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

    render() {
        if (this.state.cfSize == null) return null;
        if (this.state.cfSize == 0 ) {
            return <Alert bsStyle="warning">No lines parsed.  This may be due to a log that contains few lines, none of which match the expected expressions.</Alert>
        }

        let topProcessCounts = DataUtils.makeD3Stream('Process', this.state.groups.processGroup.top(this.state.sliderValue));
        let topPidCounts = DataUtils.makeD3Stream('PID', this.state.groups.pidGroup.top(this.state.sliderValue));
        let topUserCounts = DataUtils.makeD3Stream('User', this.state.groups.userGroup.top(this.state.sliderValue));
        let topNameCounts = DataUtils.makeD3Stream('Name', this.state.groups.nameGroup.top(this.state.sliderValue));

        const cap = 250;
        let gridData = this.state.dims.dynDim.top(cap);
        // Add the idx in for each line for the grid to select on
        gridData.forEach((l, idx) => l.idx = idx);

        return (
            <div ref="lsof-view">
                <Filtering removeFilter={this.removeFilter} filters={this.state.filters}></Filtering>
                <p>Showing top <strong>{this.state.sliderValue}</strong> results (Slide to visualize more/less)</p>
                <Spacer />
                <Slider min={1} defaultValue={this.state.sliderValue} max={20} onChange={this.updateSliderValue}></Slider>
                <Spacer />
                <div className="app-block">
                    <h3 className="title">
                        <span>LSOF Stats</span>
                        <small> ({this.state.cfSize} File Descriptors open</small>
                    </h3>
                    <div className="content">
                        {/* ************************** */}
                        {/* User stats */}
                        {/* ************************** */}
                        <Row>
                            <Col md={6}>
                                <TopCounts
                                    group={this.state.groups.userGroup}
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    field='user'
                                    title='Top User Counts'
                                    topSize={this.state.sliderValue}
                                    truncate={Infinity}
                                    inline={false}
                                    cfSize={this.state.cfSize}
                                    tooltip='Total user counts based on the current filters'>
                                </TopCounts>
                            </Col>
                            <Col md={6}>
                                <DiscreteBarChart
                                    title='Top User Counts'
                                    data={topUserCounts}
                                    field='user'
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    topSize={this.state.sliderValue}
                                    chartSize='med'
                                    showYAxis={true}>
                                </DiscreteBarChart>
                            </Col>
                        </Row>
                        {/* ************************** */}
                        {/* Process stats */}
                        {/* ************************** */}
                        <Row>
                            <Col md={6}>
                                <TopCounts
                                    group={this.state.groups.processGroup}
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    field='process'
                                    title='Top Process Counts'
                                    topSize={this.state.sliderValue}
                                    truncate={Infinity}
                                    cfSize={this.state.cfSize}
                                    inline={false}
                                    tooltip='Total method counts based on the current filters'>
                                </TopCounts>
                            </Col>
                            <Col md={6}>
                                <DiscreteBarChart
                                    title='Top Process Counts'
                                    data={topProcessCounts}
                                    field='process'
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    topSize={this.state.sliderValue}
                                    chartSize='med'
                                    showYAxis={true}>
                                </DiscreteBarChart>
                            </Col>
                        </Row>
                        {/* ************************** */}
                        {/* PID stats */}
                        {/* ************************** */}
                        <Row>
                            <Col md={6}>
                                <TopCounts
                                    group={this.state.groups.pidGroup}
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    field='pid'
                                    title='Top PID Counts'
                                    topSize={this.state.sliderValue}
                                    staggerLabels={true}
                                    truncate={Infinity}
                                    cfSize={this.state.cfSize}
                                    inline={false}
                                    tooltip='Top PID counts based on the current filters and slider'>
                                </TopCounts>
                            </Col>
                            <Col md={6}>
                                <DiscreteBarChart
                                    title='Top PID Counts'
                                    data={topPidCounts}
                                    field='pid'
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    topSize={this.state.sliderValue}
                                    chartSize='med'
                                    showYAxis={true}>
                                </DiscreteBarChart>
                            </Col>
                        </Row>
                        {/* ************************** */}
                        {/* Name stats */}
                        {/* ************************** */}
                        <Row>
                            <Col md={6}>
                                <TopCounts
                                    group={this.state.groups.nameGroup}
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    field='name'
                                    title='Top Name Counts'
                                    topSize={this.state.sliderValue}
                                    truncate={Infinity}
                                    cfSize={this.state.cfSize}
                                    inline={false}
                                    tooltip='Top Name counts based on the selected filters and slider'>
                                </TopCounts>
                            </Col>
                            <Col md={6}>
                                <DiscreteBarChart
                                    title='Top Name Counts'
                                    data={topNameCounts}
                                    field='name'
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    topSize={this.state.sliderValue}
                                    chartSize='med'
                                    rotateLabels={45}
                                    showYAxis={true}>
                                </DiscreteBarChart>
                            </Col>
                        </Row>
                    </div>

                </div>

                <Row>
                    <Col md={12}>
                        <LogDataGrid
                            data={gridData}
                            idProperty="idx"
                            columns={[
                                { name: "process", title: 'Process'},
                                { name: 'pid', title: 'PID'},
                                { name: 'user', title: 'User'},
                                { name: 'fd', title: 'FD'},
                                { name: 'type', title: 'Type'},
                                { name: 'device', title: 'Device'},
                                { name: 'size', title: 'Size'},
                                { name: 'node', title: 'Node'},
                                { name: 'name', title: 'Name'}
                            ]}
                            isPaged={true}
                            cap={cap}
                            height={500}>
                        </LogDataGrid>
                    </Col>
                </Row>

            </div>
        );
    }
}

Lsof.propTypes = {
    file: PropTypes.object.isRequired
};

export default Lsof;

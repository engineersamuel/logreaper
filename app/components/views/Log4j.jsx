import { Component, PropTypes } from "react"
import shallowEqual from "react-pure-render/shallowEqual"
import { Alert, Row, Col, Glyphicon } from "react-bootstrap"
import Slider from 'rc-slider'

import Spacer                       from "../Spacer.jsx"
import TopCounts                    from "../stats/TopCounts.jsx"
import TopSeverityFieldCounts       from "../stats/TopSeverityFieldCounts.jsx"
import Filtering                    from "../filters/Filtering.jsx"
import HorizontalBarChart           from "../charts/HorizontalBarChart.jsx"
import DiscreteBarChart             from "../charts/DiscreteBarChart.jsx"
import LineChartWithFocus           from "../charts/LineChartWithFocus.jsx"
import LogDataGrid                  from "../grid/LogDataGrid.jsx"
import Recommendations              from "./Recommendations.jsx"

import * as DataUtils               from "../../utils/dataUtils"

class Log4j extends Component {
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

    componentWillReceiveProps(nextProps) {
        this.setState(_.assign(this.state, nextProps.viewModelOpts))
    }

    componentWillUnmount() {
        if (_.isFunction(this.state.cleanUp)) {
            this.state.cleanUp();
        }
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

    renderTopSeverityFieldCounts(severity, field) {
        // showTopPercentage={1} to render the percentage for the first top item
        if (!_.get(this, `state.severityFieldMappings.${severity}.${field}.group`)) {
            console.warn(`Could not generate TopSeverityFieldCounts since the group for severity: ${severity}, field: ${field} could not be looked up.`);
        }
        return (
            <TopSeverityFieldCounts
                key={`${severity}-${field}`}
                group={this.state.severityFieldMappings[severity][field]['group']}
                filters={this.state.filters}
                addFilter={this.addFilter}
                removeFilter={this.removeFilter}
                field={field}
                severity={severity}
                topSize={this.state.sliderValue}
                cfSize={this.state.cfSize}
                showIfNoData={false}
                truncate={100}
                tooltip={`Top ${severity} log entries by count. These represent the most commonly seen ${severity} ${field} entries in the log.`}>
            </TopSeverityFieldCounts>
        )
    }

    render() {
        if (this.state.cfSize == null) return null;
        if (this.state.cfSize == 0 ) {
            return <Alert bsStyle="warning">No lines parsed.  This may be due to a log that contains few lines, none of which match the expected expressions.</Alert>
        }

        //let topSeverityCounts = this.state.groups.severityGroup.top(this.state.sliderValue);
        let timeSeriesSeverityCounts = DataUtils.makeTimeSeriesData(this.props.parseSeverities || this.props.file.identification.parseSeverities, this.state.groups.timestampGroups);

        // Gather the top warn and error messages and transform those down to the actual message values
        let recommendations = _.chain(_.filter(this.state.severityFieldMappings['ERROR']['message']['group'].order(p => p.count).top(this.state.sliderValue), item => item.value.count > 0))
            .union(_.filter(this.state.severityFieldMappings['WARN']['message']['group'].order(p => p.count).top(this.state.sliderValue), item => item.value.count > 0))
            // Pluck the key out
            .map('key')
            // The actual value is the 2nd element in the array
            .map(1)
            // Also create a quoted form
            .map(text => [text.trim(), `"${text.trim()}"`])
            .flatten()
            .value();

        //console.debug(`Recommendations: ${JSON.stringify(recommendations, null, ' ')}`);

        const cap = 250;
        let gridData = this.state.dims.timestampDim.top(cap);
        // Add the idx in for each line for the grid to select on
        gridData.forEach((l, idx) => l.idx = idx);


        let fields = ['message', 'thread', 'category'];
        let sevs = _.filter(this.state.parseSeverities, s => !_.includes(this.state.infoLevelSeverities, s));
        let topSeverityFieldCounts = _.map(fields, (field) => _.map(sevs, sev => this.renderTopSeverityFieldCounts(sev, field)));

        return (
            <div ref="apache-access-view">
                <Row>
                    <Col md={12}>
                        <h3>Log Counts by Severity</h3>
                        <LineChartWithFocus
                            data={timeSeriesSeverityCounts}
                            field='severity'
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
                <Slider min={0} defaultValue={5} max={20} onChange={this.updateSliderValue}></Slider>
                <Row>
                    <Col md={6}>
                        <div className="app-block">
                            <h3 className="title">
                                <span>Log Stats</span>
                                <small> ({this.state.cfSize} log entries parsed spanning ~{this.state.durationHumanized})</small>
                            </h3>
                            <div className="content">
                                <TopCounts
                                    group={this.state.groups.severityGroup}
                                    filters={this.state.filters}
                                    addFilter={this.addFilter}
                                    removeFilter={this.removeFilter}
                                    field='severity'
                                    title='Top Severity Counts'
                                    topSize={this.state.sliderValue}
                                    cfSize={this.state.cfSize}
                                    truncate={55}
                                    inline={false}
                                    tooltip='Total severity counts based on current filters'>
                                </TopCounts>
                                <hr/>
                                <Recommendations texts={recommendations}></Recommendations>
                                <Spacer size={60} />
                            </div>
                        </div>
                    </Col>
                    <Col md={6}>
                        <div className="app-block">
                            {topSeverityFieldCounts}
                        </div>
                    </Col>
                </Row>
                <Spacer />
                <Row>
                    <Col md={12}>
                        <LogDataGrid
                            data={gridData}
                            idProperty="idx"
                            columns={[
                                { name: 'timestamp', title: 'Timestamp'},
                                { name: 'severity', title: 'Severity'},
                                { name: 'category', title: 'Category'},
                                { name: 'thread', title: 'Thread'},
                                { name: 'message', title: 'Message'}
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

Log4j.propTypes = {
    file: PropTypes.object.isRequired,
    parseSeverities: PropTypes.array.isRequired
};

export default Log4j;

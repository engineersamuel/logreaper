import { Component, PropTypes } from "react"
import shallowEqual from "react-pure-render/shallowEqual"
import { Alert, Row, Col, Glyphicon } from "react-bootstrap"
import Slider from 'rc-slider'

import AppBlock                     from "../AppBlock.jsx"
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

class Vdsm extends Component {
    constructor(props, context) {
        super(props, context);
        this.state = _.assign({
            sliderValue: this.props.sliderValue || 10,
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
        let hasNoItems = this.state.severityFieldMappings[severity][field]['group'].size() == 1 && this.state.severityFieldMappings[severity][field]['group'].top(1)[0].value.count == 0;
        return (
            <AppBlock title={`Top ${severity} in ${field}`} key={`${severity}-${field}`} render={!hasNoItems}>
                <TopSeverityFieldCounts
                    group={this.state.severityFieldMappings[severity][field]['group']}
                    filters={this.state.filters}
                    addFilter={this.addFilter}
                    removeFilter={this.removeFilter}
                    field={field}
                    severity={severity}
                    topSize={this.state.sliderValue}
                    cfSize={this.state.cfSize}
                    truncate={55}
                    tooltip={`Top ${severity} log entries by count. These represent the most commonly seen ${severity} ${field} entries in the log.`}>
                </TopSeverityFieldCounts>
            </AppBlock>
        )
    }

    render() {
        if (this.state.cfSize == null) return null;
        if (this.state.cfSize == 0 ) {
            return <Alert bsStyle="warning">No lines parsed.  This may be due to a log that contains few lines, none of which match the expected expressions.</Alert>
        }

        // Gather the top warn and error messages and transform those down to the actual message values
        let recommendations = _.chain(_.filter(this.state.severityFieldMappings['ERROR']['command']['group'].order(p => p.count).top(this.state.sliderValue), item => item.value.count > 0))
            .union(_.filter(this.state.severityFieldMappings['WARN']['command']['group'].order(p => p.count).top(this.state.sliderValue), item => item.value.count > 0))
            // Pluck the key out
            .map('key')
            // The actual value is the 2nd element in the array
            .map(1)
            // Also create a quoted form
            .map(text => [text.trim(), `"${text.trim()}"`])
            .flatten()
            .value();

        const cap = 250;
        this.state.dims.severityCommandDim.filterFunction(objArr => _.includes(['ERROR', 'WARN'], objArr[0]));
        let gridData = this.state.dims.severityCommandDim.top(cap);
        // Add the idx in for each line for the grid to select on
        gridData.forEach((l, idx) => l.idx = idx);

        let fields = ['command'];
        let sevs = _.filter(this.state.parseSeverities, s => !_.includes(this.state.infoLevelSeverities, s));
        let topSeverityFieldCounts = _.map(fields, (field) => _.map(sevs, sev => this.renderTopSeverityFieldCounts(sev, field)));

        return (
            <div ref="vdsm-quick-view">
                <Filtering removeFilter={this.removeFilter} filters={this.state.filters}></Filtering>
                <p>Showing top <strong>{this.state.sliderValue}</strong> results (Slide to visualize more/less)</p>
                <Spacer />
                <Slider min={1} defaultValue={this.state.sliderValue} max={20} onChange={this.updateSliderValue}></Slider>
                <Spacer />
                <Row>
                    <Col md={6}>
                        <AppBlock title={`Solution Recommendations`}>
                            <Recommendations texts={recommendations}></Recommendations>
                        </AppBlock>
                    </Col>
                    <Col md={6}>
                        {topSeverityFieldCounts}
                    </Col>
                </Row>
                <Spacer />
                <Row>
                    <Col md={12}>
                        <LogDataGrid
                            data={gridData}
                            idProperty="idx"
                            columns={[
                                { name: 'timestamp', title: 'Timestamp', render: (v) => (new Date(v).toLocaleString())},
                                { name: 'threadId', title: 'Thread'},
                                { name: 'severity', title: 'Severity'},
                                { name: 'component', title: 'Component'},
                                { name: 'module', title: 'Module'},
                                { name: 'command', title: 'Command'}
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

Vdsm.propTypes = {
    file: PropTypes.object.isRequired
};

export default Vdsm;

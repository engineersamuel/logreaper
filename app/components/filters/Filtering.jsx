import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { PanelGroup, Panel, Glyphicon } from "react-bootstrap"

import Spacer           from '../Spacer.jsx'
import DivOrSpan        from '../DivOrSpan.jsx'

class Filtering extends Component {

    lowerCase(str) {
        return str.charAt(0).toLowerCase() + str.slice(1);
    }
    removeFilter(item, e) {
        e.preventDefault();
        e.stopPropagation();
        this.props.removeFilter(item);
    }
    formatTimestamp(d) {
        return moment(d).format('YYYY-MM-DD HH:mm:ss');
    }
    generateItemValueDisplay(item) {
        let truncatedData;
        if (item.field === 'timestamp') {
            return item.field + ": [" + (this.formatTimestamp(item.start)) + " - " + (this.formatTimestamp(item.end)) + "]";
        } else {
            truncatedData = ("" + item.key).length > this.props.truncateTo ? ("" + item.key).substring(0, this.props.truncateTo) + '...' : item.key;
            return item.field + ": " + truncatedData;
        }
    }
    renderItems(filters) {
        let divClassNames = "field-item taxonomy-list taxonomy-portal_tag";
        let aClassNames = "pointer meta_portal_tag top-error-content current-filter-item filter-selected";
        return filters.map((item, idx) => {
            let encodedAndStringifiedItem = encodeURIComponent(JSON.stringify(item));
            return (
                <div key={`filter-${item.field}-${idx}`} className={divClassNames}>
                    <a className={aClassNames} value={encodedAndStringifiedItem} onClick={this.removeFilter.bind(this, item)}>
                        {this.generateItemValueDisplay(item)}
                        &nbsp;
                        <Glyphicon glyph="remove"></Glyphicon>
                    </a>
                    <Spacer size={5} />
                </div>
            );
        });

    }
    render() {
        return (
            <PanelGroup defaultActiveKey={this.props.filters.length == 0 ? "2" : "1"} accordion>
                <Panel header={`${this.props.filters.length} Filter(s)`} eventKey="1">
                    {this.renderItems(this.props.filters)}
                </Panel>
            </PanelGroup>
        )
    }
}

Filtering.propTypes = {
    filters: PropTypes.array.isRequired,
    removeFilter: PropTypes.func.isRequired
};

export default Filtering;

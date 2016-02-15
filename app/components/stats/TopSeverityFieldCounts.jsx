import { Component, PropTypes } from "react";
import shallowEqual from "react-pure-render/shallowEqual"
import { Row, Col, Glyphicon } from "react-bootstrap"

import Spacer           from '../Spacer.jsx'
import DivOrSpan        from '../DivOrSpan.jsx'

class TopSeverityFieldCounts extends Component {

    //shouldComponentUpdate(nextProps, nextState) {
    //    return !shallowEqual(this.props.progress, nextProps.progress);
    //}

    //filtersContainItem(item) {
    //  return _.findIndex(this.props.filters, item) != -1
    //}

    transformItem(item) {
      return {field: this.props.field.charAt(0).toLowerCase() + this.props.field.slice(1), key: item.key}
    }

    onClick(item, e) {
        e.preventDefault();

        item = this.transformItem(item);

        if (this.isItemFiltered(item)) {
            this.props.removeFilter(item)
        } else {
            this.props.addFilter(item);
        }
    }

    createSeverityClass(sev) {
      return sev != null ? "severity-#{sev}" : "";
    }

    /*item = {
     field: ...,
     value: (this is actually the key!)
     }*/
    isItemFiltered(item) {
        item = this.transformItem(item);
        return _.findIndex(this.props.filters, item) !== -1;
    }
    renderFilterIcon(item) {
        if (this.isItemFiltered(item)) {
            return <Glyphicon className="black" glyph="remove"></Glyphicon>;
        } else {
            return <Glyphicon className="green" glyph="filter"></Glyphicon>;
        }
    }

    renderTooltip() {
        if (this.props.tooltip == null) return null;
        return <i className="fa fa-question-circle" title={this.props.tooltip}></i>
    }

    renderTopPercentage(count, idx) {
        if (this.props.showTopPercentage != null && (idx < this.props.showTopPercentage)) {
            let percentage = ((count / this.props.cfSize) * 100).toFixed(0);
            return <span>(comprises {percentage}% of entries)</span>
        }
    }

    renderItem(item, idx) {
        let truncatedValue = _.truncate(item.key, {length: this.props.truncate});

        return (
            <div key={`top-${this.props.field}-${idx}`}>
                <a className="pointer" onClick={this.onClick.bind(this, item)}>
                    {this.renderFilterIcon(item)}
                </a>
                &nbsp;
                <strong>{_.get(item, 'value.count', item.value)}</strong>
                &nbsp;
                <span className="field-item taxonomy-list taxonomy-portal_tag">
                    <span>{truncatedValue}</span>
                    &nbsp;&nbsp;
                    {this.renderTopPercentage(_.get(item, 'value.count', item.value), idx)}
                </span>
            </div>
        )
    }

    renderItems(topSevFieldCounts) {
        if (topSevFieldCounts.length == 0) return <small>No data</small>;
        return _.map(topSevFieldCounts, (item, idx) => this.renderItem(item, idx));
    }

    render() {
        const { field, severity, showIfNoData } = this.props;
        let topSevFieldCounts = _.filter(this.props.group.order(p => p.count).top(this.props.topSize || 5), item => item.value.count > 0);

        // Short circuit here if we don't want to show anything if no data
        if (!showIfNoData && topSevFieldCounts.length == 0) return null;

        topSevFieldCounts = _.map(topSevFieldCounts, t => {
            return {
                key: t.key[1],
                value: t.value.count
            };
        });

        return (
            <div>
                <h3>{`Top ${severity} in ${field}`}</h3>
                {this.renderItems(topSevFieldCounts)}
                <hr/>
            </div>
        )
    }
}
TopSeverityFieldCounts.defaultProps = {
    showIfNoData: true,
    truncate: 40
};

TopSeverityFieldCounts.propTypes = {
    addFilter: PropTypes.func.isRequired,
    removeFilter: PropTypes.func.isRequired,
    filters: PropTypes.array.isRequired,
    group: PropTypes.object.isRequired,
    field: PropTypes.string.isRequired,
    severity: PropTypes.string.isRequired,
    cfSize: PropTypes.number.isRequired,
    topSize: PropTypes.number,
    truncate: PropTypes.number,
    showIfNoData: PropTypes.bool

};

export default TopSeverityFieldCounts;

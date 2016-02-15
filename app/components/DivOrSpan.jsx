const DivOrSpan = ({children, ...rest}) => {
    if (rest.inline) {
        return <span>{children}</span>
    } else {
        return <div>{children}</div>
    }
};

export default DivOrSpan;